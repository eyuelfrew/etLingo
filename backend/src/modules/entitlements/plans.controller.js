import { SubscriptionPlan } from './plans.models.js';
import { Entitlement, CheckoutIntent } from './entitlements.models.js';
import { asyncHandler, badRequest, notFound, unauthorized } from '../../core/http.js';
import { createHostedPayment, verifyPayment, chapaEnabled } from '../../core/chapa.js';
import { AppUser } from '../users/users.models.js';
import { Unit } from '../content/content.models.js';

const PERIOD_DAYS = { month: 31, year: 365, trial: 7 };

function pick(obj, fields) {
  const out = {};
  for (const f of fields) if (obj[f] !== undefined) out[f] = obj[f];
  return out;
}

function planOut(r) {
  const x = r.toJSON ? r.toJSON() : r;
  return {
    id: x.id,
    sku: x.sku,
    title: x.title,
    subtitle: x.subtitle || '',
    period: x.period || 'month',
    priceCents: x.price_cents ?? 0,
    currency: x.currency || 'ETB',
    features: Array.isArray(x.features) ? x.features : [],
    badge: x.badge || '',
    isActive: !!x.is_active,
    isHighlighted: !!x.is_highlighted,
    sortOrder: x.sort_order ?? 0,
    priceLabel:
      (x.price_cents ?? 0) === 0
        ? 'Free'
        : `${((x.price_cents ?? 0) / 100).toFixed(2)} ${x.currency || 'ETB'}`,
    periodLabel:
      x.period === 'year' ? '/ year' : x.period === 'trial' ? 'trial' : '/ month',
  };
}

const planFields = [
  'sku', 'title', 'subtitle', 'period', 'price_cents', 'currency',
  'features', 'badge', 'is_active', 'is_highlighted', 'sort_order',
];

export async function listActivePlans() {
  const rows = await SubscriptionPlan.findAll({
    where: { is_active: true },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  return rows.map(planOut);
}

/** True when user unlocked this chapter (permanent purchase). */
export async function userOwnsUnit(userId, unitId) {
  if (!userId || !unitId) return false;
  const row = await Entitlement.findOne({
    where: { user_id: userId, scope: 'unit', scope_id: unitId },
  });
  if (!row) return false;
  if (row.expires_at && new Date(row.expires_at) < new Date()) return false;
  return true;
}

/** All unlocked unit ids for a user. */
export async function ownedUnitIds(userId) {
  if (!userId) return [];
  const rows = await Entitlement.findAll({
    where: { user_id: userId, scope: 'unit' },
  });
  const now = new Date();
  return rows
    .filter((r) => !r.expires_at || new Date(r.expires_at) >= now)
    .map((r) => r.scope_id)
    .filter(Boolean);
}

async function grantUnit(userId, unitId, source = 'purchase', note = '') {
  const sku = `unit:${unitId}`;
  await Entitlement.findOrCreate({
    where: { user_id: userId, sku },
    defaults: {
      user_id: userId,
      sku,
      scope: 'unit',
      scope_id: unitId,
      source,
      expires_at: null,
      note,
    },
  });
}

// ── Admin ────────────────────────────────────────────────────────────────────

export const adminListPlans = asyncHandler(async (_req, res) => {
  const rows = await SubscriptionPlan.findAll({
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  res.json(rows.map(planOut));
});

export const adminCreatePlan = asyncHandler(async (req, res) => {
  const data = pick(req.body, planFields);
  if (!data.sku) throw badRequest('sku is required');
  if (!data.title) throw badRequest('title is required');
  data.sku = String(data.sku).trim().toLowerCase();
  const exists = await SubscriptionPlan.findOne({ where: { sku: data.sku } });
  if (exists) throw badRequest(`Plan "${data.sku}" already exists`);
  const row = await SubscriptionPlan.create(data);
  res.status(201).json(planOut(row));
});

export const adminUpdatePlan = asyncHandler(async (req, res) => {
  const row = await SubscriptionPlan.findByPk(req.params.id);
  if (!row) throw notFound('Plan not found');
  await row.update(pick(req.body, planFields));
  res.json(planOut(row));
});

export const adminDeletePlan = asyncHandler(async (req, res) => {
  const row = await SubscriptionPlan.findByPk(req.params.id);
  if (!row) throw notFound('Plan not found');
  await row.destroy();
  res.status(204).end();
});

// ── App ──────────────────────────────────────────────────────────────────────

export const listOffers = asyncHandler(async (_req, res) => {
  res.json({
    model: 'subscription',
    paymentEnabled: false,
    plans: await listActivePlans(),
  });
});

export const createCheckoutIntent = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const userId = Number(req.auth.sub);

  // ── Chapter / unit purchase (primary model) ──
  const unitId = Number(req.body?.unitId || req.body?.unit_id);
  if (unitId) {
    const unit = await Unit.findByPk(unitId);
    if (!unit) throw notFound('Chapter not found');
    const cents = Number(unit.price_cents) || 0;
    if (cents <= 0) throw badRequest('This chapter is free');

    if (await userOwnsUnit(userId, unitId)) {
      return res.status(200).json({
        status: 'owned',
        requiresPayment: false,
        message: 'You already unlocked this chapter.',
        purchasedUnitIds: await ownedUnitIds(userId),
      });
    }

    const intent = await CheckoutIntent.create({
      user_id: userId,
      sku: `unit:${unitId}`,
      amount_cents: cents,
      currency: 'ETB',
      status: 'pending',
      provider: chapaEnabled() ? 'chapa' : 'none',
      payload: { unitId, title: unit.title },
    });

    if (!chapaEnabled()) {
      return res.status(201).json({
        intentId: intent.id,
        sku: `unit:${unitId}`,
        status: 'unpaid',
        requiresPayment: false,
        paymentUrl: null,
        message: 'Payment is not configured on the server.',
      });
    }

    const user = await AppUser.findByPk(userId);
    const txRef = `ETL-U${unitId}-${intent.id}-${Date.now().toString(36)}`;
    let checkout;
    try {
      checkout = await createHostedPayment({
        amountCents: cents,
        currency: 'ETB',
        email: user?.email,
        firstName: (user?.display_name || 'Learner').slice(0, 40),
        lastName: unit.title.slice(0, 20),
        phone: req.body?.phone || '',
        txRef,
        meta: { unitId, title: `Chapter: ${unit.title}`, userId },
      });
    } catch (err) {
      await intent.update({ status: 'failed', payload: { error: String(err.message) } });
      throw badRequest(`Payment start failed: ${err.message}`);
    }

    await intent.update({
      provider: 'chapa',
      provider_ref: txRef,
      payload: {
        unitId,
        title: unit.title,
        checkoutUrl: checkout.checkoutUrl,
      },
    });

    return res.status(201).json({
      intentId: intent.id,
      txRef,
      sku: `unit:${unitId}`,
      unitId,
      amountCents: cents,
      currency: 'ETB',
      status: intent.status,
      requiresPayment: true,
      paymentUrl: checkout.checkoutUrl,
      message: `Unlock “${unit.title}” — open payment.`,
    });
  }

  // ── Legacy plan SKU (optional) ──
  const sku = String(req.body?.sku || '');
  const plan = await SubscriptionPlan.findOne({ where: { sku, is_active: true } });
  if (!plan) throw badRequest('Unknown product (use unitId for chapters)');

  const intent = await CheckoutIntent.create({
    user_id: userId,
    sku,
    amount_cents: plan.price_cents,
    currency: plan.currency,
    status: 'pending',
    provider: chapaEnabled() ? 'chapa' : 'none',
    payload: { title: plan.title, period: plan.period },
  });

  // Free / zero-price → grant immediately (test / trial packages).
  if (!plan.price_cents) {
    const days = PERIOD_DAYS[plan.period] || 31;
    await intent.update({ status: 'paid' });
    await Entitlement.findOrCreate({
      where: { user_id: userId, sku },
      defaults: {
        user_id: userId,
        sku,
        scope: 'all',
        source: 'trial',
        expires_at: new Date(Date.now() + days * 86400000),
        note: `free ${sku}`,
      },
    });
    res.status(201).json({
      intentId: intent.id,
      sku,
      status: 'paid',
      requiresPayment: false,
      paymentUrl: null,
      message: 'Activated (free package).',
    });
    return;
  }

  if (!chapaEnabled()) {
    res.status(201).json({
      intentId: intent.id,
      sku,
      status: 'unpaid',
      requiresPayment: false,
      paymentUrl: null,
      message: 'Payments are not configured on the server.',
    });
    return;
  }

  const user = await AppUser.findByPk(userId);
  const txRef = `ETL-${intent.id}-${Date.now().toString(36)}`;
  let checkout;
  try {
    checkout = await createHostedPayment({
      amountCents: plan.price_cents,
      currency: plan.currency || 'ETB',
      email: user?.email,
      firstName: (user?.display_name || 'Learner').slice(0, 40),
      lastName: 'etLingo',
      phone: req.body?.phone || '',
      txRef,
      meta: { sku, title: plan.title, period: plan.period, userId },
    });
  } catch (err) {
    // Surface Chapa's message (e.g. invalid key) instead of a generic 500.
    await intent.update({ status: 'failed', payload: { error: String(err.message) } });
    throw badRequest(`Payment start failed: ${err.message}`);
  }
  await intent.update({
    provider: 'chapa',
    provider_ref: txRef,
    payload: {
      title: plan.title,
      period: plan.period,
      checkoutUrl: checkout.checkoutUrl,
    },
  });

  res.status(201).json({
    intentId: intent.id,
    txRef,
    sku,
    amountCents: plan.price_cents,
    currency: plan.currency,
    status: intent.status,
    requiresPayment: true,
    paymentUrl: checkout.checkoutUrl,
    message: 'Open the payment link to complete subscription.',
  });
});

/**
 * GET /app/checkout/:ref/status — poll after Chapa return.
 * Also used as a manual verify: POST /app/checkout/:ref/verify
 */
export const verifyCheckout = asyncHandler(async (req, res) => {
  const ref = String(req.params.ref || '');
  const intent = await CheckoutIntent.findOne({ where: { provider_ref: ref } });
  if (!intent) throw notFound('Payment not found');
  const isAdmin = req.auth?.role && req.auth.role !== 'app_user';
  const isOwner =
    req.auth?.sub != null && Number(req.auth.sub) === Number(intent.user_id);
  if (!isAdmin && !isOwner) throw unauthorized();

  if (intent.status === 'paid') {
    return res.json({ status: 'paid', sku: intent.sku });
  }

  const result = await verifyPayment(ref);
  if (result.ok) {
    // Unit purchase (sku unit:12)
    if (String(intent.sku).startsWith('unit:')) {
      const unitId = Number(intent.sku.split(':')[1]) || intent.payload?.unitId;
      await intent.update({ status: 'paid' });
      if (unitId) await grantUnit(intent.user_id, unitId, 'purchase', `chapa ${ref}`);
      return res.json({
        status: 'paid',
        sku: intent.sku,
        unitId: unitId || null,
        purchasedUnitIds: await ownedUnitIds(intent.user_id),
      });
    }
    const plan = await SubscriptionPlan.findOne({ where: { sku: intent.sku } });
    const days = PERIOD_DAYS[plan?.period || 'month'] || 31;
    await intent.update({ status: 'paid' });
    await Entitlement.findOrCreate({
      where: { user_id: intent.user_id, sku: intent.sku },
      defaults: {
        user_id: intent.user_id,
        sku: intent.sku,
        scope: 'all',
        source: 'purchase',
        expires_at: new Date(Date.now() + days * 86400000),
        note: `chapa ${ref}`,
      },
    });
    return res.json({ status: 'paid', sku: intent.sku });
  }

  if (result.status === 'failed') {
    await intent.update({ status: 'failed' });
    return res.json({ status: 'failed', sku: intent.sku });
  }
  res.json({ status: 'pending', sku: intent.sku });
});

/** Complete stub kept for admin / non-Chapa paths. */
export const completeCheckout = asyncHandler(async (req, res) => {
  const intent = await CheckoutIntent.findByPk(req.params.id);
  if (!intent) throw notFound('Intent not found');
  const isAdmin = req.auth?.role && req.auth.role !== 'app_user';
  const isOwner =
    req.auth?.sub != null && Number(req.auth.sub) === Number(intent.user_id);
  if (!isAdmin && !isOwner) throw unauthorized();

  // Prefer server verify when we have a Chapa reference.
  if (intent.provider_ref && intent.provider === 'chapa') {
    return verifyCheckout(req, res);
  }

  const paid = req.body?.paid === true;
  await intent.update({ status: paid ? 'paid' : 'failed' });
  if (paid) {
    const plan = await SubscriptionPlan.findOne({ where: { sku: intent.sku } });
    const days = PERIOD_DAYS[plan?.period || 'month'] || 31;
    await Entitlement.findOrCreate({
      where: { user_id: intent.user_id, sku: intent.sku },
      defaults: {
        user_id: intent.user_id,
        sku: intent.sku,
        scope: 'all',
        source: 'purchase',
        expires_at: new Date(Date.now() + days * 86400000),
        note: `checkout ${intent.id}`,
      },
    });
  }
  res.json({ id: intent.id, status: intent.status });
});
