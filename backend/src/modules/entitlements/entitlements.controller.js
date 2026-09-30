import { Entitlement, CheckoutIntent } from './entitlements.models.js';
import { asyncHandler, badRequest, notFound, unauthorized } from '../../core/http.js';

/**
 * Subscription plans only — not per-course unlocks.
 * `enabled: false` until a payment gateway is plugged in.
 */
export const SKUS = [
  {
    sku: 'sub_monthly',
    title: 'Monthly',
    priceCents: 0,
    currency: 'ETB',
    period: 'month',
    description: 'Full app — all languages, culture, scripts. Monthly.',
    enabled: false,
  },
  {
    sku: 'sub_yearly',
    title: 'Yearly',
    priceCents: 0,
    currency: 'ETB',
    period: 'year',
    description: 'Full app — all languages, culture, scripts. Best value.',
    enabled: false,
  },
];

const PERIOD_DAYS = { month: 31, year: 365 };

function isActive(row, now = new Date()) {
  if (!row) return false;
  if (row.expires_at && new Date(row.expires_at) < now) return false;
  return true;
}

/** True when the user has an active subscription (any sub_* entitlement). */
export async function userHasSubscription(userId) {
  if (!userId) return false;
  const rows = await Entitlement.findAll({ where: { user_id: userId } });
  const now = new Date();
  return rows.some((r) => {
    if (!isActive(r, now)) return false;
    const sku = String(r.sku || '');
    return sku.startsWith('sub_') || r.scope === 'all';
  });
}

export const myEntitlements = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const rows = await Entitlement.findAll({
    where: { user_id: Number(req.auth.sub) },
    order: [['granted_at', 'DESC']],
    limit: 50,
  });
  const now = new Date();
  const sub = rows.find((r) => isActive(r, now) && String(r.sku || '').startsWith('sub_'));
  res.json({
    subscribed: !!sub,
    plan: sub ? String(sub.sku) : null,
    expiresAt: sub ? sub.expires_at : null,
    items: rows.map((r) => ({
      id: r.id,
      sku: r.sku,
      source: r.source,
      expiresAt: r.expires_at,
      active: isActive(r, now),
      note: r.note,
    })),
  });
});

export const grantEntitlement = asyncHandler(async (req, res) => {
  const userId = Number(req.body?.user_id || req.body?.userId);
  if (!userId) throw badRequest('user_id is required');
  const sku = String(req.body?.sku || 'sub_monthly');
  const days = Number(req.body?.days) || null;
  const expires = days ? new Date(Date.now() + days * 86400000) : null;

  const [row, created] = await Entitlement.findOrCreate({
    where: { user_id: userId, sku },
    defaults: {
      user_id: userId,
      sku,
      scope: 'all',
      source: 'admin',
      expires_at: expires,
      note: String(req.body?.note || '').slice(0, 200),
    },
  });
  if (!created) {
    await row.update({
      expires_at: expires,
      note: String(req.body?.note || row.note || '').slice(0, 200),
    });
  }
  res.status(created ? 201 : 200).json({
    id: row.id,
    userId: row.user_id,
    sku: row.sku,
    expiresAt: row.expires_at,
  });
});

export const revokeEntitlement = asyncHandler(async (req, res) => {
  const row = await Entitlement.findByPk(req.params.id);
  if (!row) throw notFound('Entitlement not found');
  await row.destroy();
  res.status(204).end();
});

export const adminListEntitlements = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.user_id) where.user_id = Number(req.query.user_id);
  const rows = await Entitlement.findAll({
    where,
    order: [['granted_at', 'DESC']],
    limit: 200,
  });
  res.json(rows.map((r) => ({
    id: r.id,
    userId: r.user_id,
    sku: r.sku,
    source: r.source,
    grantedAt: r.granted_at,
    expiresAt: r.expires_at,
    note: r.note,
  })));
});
