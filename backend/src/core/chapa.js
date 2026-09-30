/**
 * Chapa hosted payments (Ethiopia) — subscriptions.
 * Test keys via env: CHAPA_SECRET_KEY / CHAPA_PUBLIC_KEY.
 * API: https://api.chapa.co/v1 (initialize + verify).
 */

const CHAPA_BASE = process.env.CHAPA_API_BASE || 'https://api.chapa.co/v1';

function secret() {
  return process.env.CHAPA_SECRET_KEY || '';
}

export function chapaEnabled() {
  return Boolean(secret());
}

export function chapaStatus() {
  return {
    enabled: chapaEnabled(),
    mode: (secret() || '').startsWith('CHASECK_TEST') ? 'test' : 'live',
  };
}

/** Chapa rejects some domains (example.com, test.com) — normalize. */
function safeEmail(email, userId = 0) {
  let e = String(email || '').trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e) ||
      /@(example|test|localhost)\./.test(e)) {
    e = `learner${userId || 0}@gmail.com`;
  }
  return e;
}

/**
 * Create a hosted checkout session.
 * @returns {{ checkoutUrl: string, reference: string }}
 */
export async function createHostedPayment({
  amountCents,
  currency = 'ETB',
  email,
  firstName = 'Learner',
  lastName = '',
  phone = '',
  txRef,
  meta = {},
}) {
  if (!chapaEnabled()) {
    throw new Error('Chapa is not configured (CHAPA_SECRET_KEY missing)');
  }
  const amount = Math.max(1, Number(amountCents || 0) / 100);
  // Match Chapa v1 sample (docs): amount as string, phone_number, customization.
  const body = {
    amount: amount.toFixed(2),
    currency,
    email: safeEmail(email, meta?.userId),
    first_name: String(firstName || 'Learner').slice(0, 40),
    last_name: String(lastName || 'etLingo').slice(0, 40),
    phone_number: String(phone || '').slice(0, 20) || undefined,
    tx_ref: txRef,
    callback_url: process.env.CHAPA_CALLBACK_URL || undefined,
    return_url: process.env.CHAPA_RETURN_URL || undefined,
    'customization[title]': 'etLingo',
    'customization[description]': String(meta?.title || 'Subscription').slice(0, 80),
    'meta[hide_receipt]': 'true',
  };
  // Strip undefined so Chapa doesn't reject empty optional fields.
  for (const k of Object.keys(body)) {
    if (body[k] === undefined) delete body[k];
  }

  const res = await fetch(`${CHAPA_BASE}/transaction/initialize`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${secret()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  const checkoutUrl = json?.data?.checkout_url;
  if (!res.ok || json?.status !== 'success' || !checkoutUrl) {
    const msg = json?.message
        ? (typeof json.message === 'string'
            ? json.message
            : JSON.stringify(json.message))
        : `Chapa error ${res.status}`;
    console.error('[chapa] create failed', msg, json);
    throw new Error(msg);
  }
  return {
    checkoutUrl,
    reference: txRef,
    raw: json.data,
  };
}

/** Verify a transaction on Chapa (server-side — never trust the client). */
export async function verifyPayment(reference) {
  if (!chapaEnabled()) {
    throw new Error('Chapa is not configured (CHAPA_SECRET_KEY missing)');
  }
  const res = await fetch(`${CHAPA_BASE}/transaction/verify/${reference}`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${secret()}`,
      'Content-Type': 'application/json',
    },
  });
  const json = await res.json().catch(() => ({}));
  const data = json?.data;
  return {
    ok: res.ok && json?.status === 'success' && data?.status === 'success',
    status: data?.status || json?.status || 'failed',
    amount: data?.amount,
    currency: data?.currency,
    reference,
    raw: json,
  };
}
