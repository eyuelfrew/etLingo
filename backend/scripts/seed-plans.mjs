/**
 * Seed default subscription packages (idempotent by sku).
 */
const base = 'http://localhost:5050/api/v1';

async function api(path, method = 'GET', token, body) {
  const r = await fetch(base + path, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: 'Bearer ' + token } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await r.text();
  try {
    return { status: r.status, body: JSON.parse(text) };
  } catch {
    return { status: r.status, body: text };
  }
}

const login = await api('/auth/login', 'POST', null, {
  email: 'admin@etlang.app',
  password: 'admin123',
});
const token = login.body.token;
if (!token) {
  console.error('login failed', login);
  process.exit(1);
}

const PLANS = [
  {
    sku: 'sub_trial',
    title: 'Free preview',
    subtitle: 'Try etLingo with free lessons',
    period: 'trial',
    price_cents: 0,
    currency: 'ETB',
    features: ['All free lessons', 'Scripts & alphabet', 'Topic packs'],
    badge: '',
    is_active: 1,
    is_highlighted: 0,
    sort_order: 0,
  },
  {
    sku: 'sub_monthly',
    title: 'Monthly',
    subtitle: 'Unlock premium chapters',
    period: 'month',
    price_cents: 0,
    currency: 'ETB',
    features: ['Everything free', 'Premium chapters', 'Culture packs'],
    badge: 'Popular',
    is_active: 1,
    is_highlighted: 1,
    sort_order: 1,
  },
  {
    sku: 'sub_yearly',
    title: 'Yearly',
    subtitle: 'Best value — two months free',
    period: 'year',
    price_cents: 0,
    currency: 'ETB',
    features: ['Everything in Monthly', 'Priority features', 'Best price'],
    badge: 'Best value',
    is_active: 1,
    is_highlighted: 0,
    sort_order: 2,
  },
];

const existing = await api('/admin/plans', 'GET', token);
const have = new Set((existing.body || []).map((p) => p.sku));
for (const p of PLANS) {
  if (have.has(p.sku)) {
    console.log('plan exists', p.sku);
    continue;
  }
  const r = await api('/admin/plans', 'POST', token, p);
  console.log('plan', p.sku, r.status, r.body?.id);
}

const offers = await api('/app/offers');
console.log('offers', offers.status, (offers.body?.plans || []).map((x) => x.sku).join(', '));
console.log('done');
