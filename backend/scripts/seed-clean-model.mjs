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
if (!login.body?.token) {
  console.error('login failed', login);
  process.exit(1);
}
const token = login.body.token;

const courses = [
  {
    code: 'am',
    name: 'Amharic',
    native_name: 'አማርኛ',
    script_preview: 'ሰላም እንዴት ነህ?',
    speakers: '~32M',
    region: 'Ethiopia',
    color_hex: '#078930',
    dark_hex: '#056B24',
    hello_target: 'ሰላም',
    hello_meaning: 'Hello',
    icon: 'waving_hand_rounded',
    sort_order: 0,
    is_active: 1,
  },
  {
    code: 'om',
    name: 'Afaan Oromo',
    native_name: 'Afaan Oromoo',
    script_preview: 'Akkam jirta?',
    speakers: '~37M',
    region: 'Ethiopia',
    color_hex: '#D94F04',
    dark_hex: '#B03D03',
    hello_target: 'Akkam',
    hello_meaning: 'Hello',
    icon: 'waving_hand_rounded',
    sort_order: 1,
    is_active: 1,
  },
  {
    code: 'ti',
    name: 'Tigrinya',
    native_name: 'ትግርኛ',
    script_preview: 'ሰላም',
    speakers: '~7M',
    region: 'Eritrea/Ethiopia',
    color_hex: '#1155CC',
    dark_hex: '#0D44A0',
    hello_target: 'ሰላማሌ',
    hello_meaning: 'Hello',
    icon: 'waving_hand_rounded',
    sort_order: 2,
    is_active: 1,
  },
  {
    code: 'so',
    name: 'Somali',
    native_name: 'Soomaali',
    script_preview: 'Nabad? Sidee tahay?',
    speakers: '~22M',
    region: 'Somalia',
    color_hex: '#4C6EF5',
    dark_hex: '#3B5BDB',
    hello_target: 'Nabad',
    hello_meaning: 'Peace',
    icon: 'waving_hand_rounded',
    sort_order: 3,
    is_active: 1,
  },
];

const bases = [
  { code: 'en', name: 'English', native_name: 'English', is_active: 1, sort_order: 0 },
  { code: 'am', name: 'Amharic', native_name: 'አማርኛ', is_active: 1, sort_order: 1 },
  { code: 'om', name: 'Afaan Oromoo', native_name: 'Afaan Oromoo', is_active: 1, sort_order: 2 },
  { code: 'ti', name: 'Tigrinya', native_name: 'ትግርኛ', is_active: 1, sort_order: 3 },
  { code: 'so', name: 'Somali', native_name: 'Soomaali', is_active: 1, sort_order: 4 },
];

for (const c of courses) {
  const r = await api('/admin/languages', 'POST', token, c);
  console.log('course', c.code, r.status, r.body?.id ?? r.body);
}

for (const b of bases) {
  const r = await api('/admin/base-languages', 'POST', token, b);
  console.log('base', b.code, r.status, r.body?.id ?? r.body);
}

const stats = await api('/admin/stats', 'GET', token);
console.log('stats', stats.body);
const appBase = await api('/app/base-languages', 'GET');
console.log('app base langs', appBase.body?.map((b) => b.id));
const appLangs = await api('/app/languages', 'GET');
console.log('app courses', appLangs.body?.map((l) => l.id));
