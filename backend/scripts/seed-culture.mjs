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

const langs = await api('/admin/languages', 'GET', token);
const am = langs.body.find((l) => l.code === 'am');
if (!am) {
  console.error('no amharic');
  process.exit(1);
}

const existing = await api(
  `/admin/culture-units?language_id=${am.id}`,
  'GET',
  token,
);
if (existing.body?.length) {
  console.log('culture units already seeded', existing.body.length);
  process.exit(0);
}

const unit = await api('/admin/culture-units', 'POST', token, {
  language_id: am.id,
  title: 'ቡና · Coffee ceremony',
  subtitle: 'From green bean to three rounds',
  theme: 'coffee',
  color_hex: '#6B3F1D',
  dark_hex: '#3E2512',
  icon: 'coffee_rounded',
  sort_order: 0,
  is_active: 1,
});
console.log('unit', unit.status, unit.body?.id);
const unitId = unit.body.id;

const cards = [
  {
    kind: 'fact',
    title: 'What is a buna ceremony?',
    body: 'Coffee is hospitality. Roasting beans, the jebena, and three small cups mark friendship and time together.',
    content: {
      en: {
        title: 'What is a buna ceremony?',
        body: 'Coffee is hospitality. Roasting beans, the jebena, and three small cups mark friendship and time together.',
      },
      so: {
        title: 'Waa maxay xafladda buna?',
        body: 'Bunuhu waa martisoorka. Dubista sababaha, jebena, iyo saddex koob yar oo wadajir ah.',
      },
    },
    vocab: [],
    xp_reward: 5,
    sort_order: 0,
  },
  {
    kind: 'proverb',
    title: 'ቡና እየሞቀ ነው',
    body: 'Coffee and talk go together when it is hot — enjoy the moment.',
    translit: 'buna eye moqe new',
    content: {
      en: {
        title: 'ቡና እየሞቀ ነው',
        body: 'Coffee and talk go together when it is hot — enjoy the moment.',
      },
      so: {
        title: 'ቡና እየሞቀ ነው',
        body: 'Bun iyo hadal waxay wada socdaan markay kulushahay — raaxo daqiiqadda.',
      },
    },
    vocab: [],
    xp_reward: 5,
    sort_order: 1,
  },
  {
    kind: 'vocab',
    title: 'Coffee words',
    body: 'Say the words while the smell is still in the air.',
    content: {
      en: {
        title: 'Coffee words',
        body: 'Say the words while the smell is still in the air.',
      },
    },
    vocab: [
      {
        target: 'ቡና',
        translit: 'buna',
        meanings: { en: 'Coffee', so: 'Bun' },
      },
      {
        target: 'ጀበና',
        translit: 'jebena',
        meanings: { en: 'Coffee pot', so: 'Dab-jebena' },
      },
      {
        target: 'ስኳር',
        translit: 'sikwar',
        meanings: { en: 'Sugar', sonkuur: '', so: 'Sokor' },
      },
      {
        target: 'አቦል',
        translit: 'abol',
        meanings: { en: 'First cup', so: 'Koobka koowaad' },
      },
    ],
    xp_reward: 5,
    sort_order: 2,
  },
  {
    kind: 'steps',
    title: 'Three rounds',
    body: 'Abol, tona, baraka — three cups, one welcome.',
    content: {
      en: {
        title: 'Three rounds',
        body: 'Abol, tona, baraka — three cups, one welcome.',
      },
      so: {
        title: 'Saddex wareeg',
        body: 'Abol, tona, baraka — saddex koob, hal soo dhaweyn.',
      },
    },
    vocab: [],
    xp_reward: 5,
    sort_order: 3,
  },
];

for (const c of cards) {
  const r = await api('/admin/culture-cards', 'POST', token, {
    ...c,
    culture_unit_id: unitId,
    content: c.content,
  });
  console.log('card', c.title, r.status, r.body?.id || r.body);
}

const boot = await api(`/app/culture/${am.code}`);
console.log(
  'bootstrap',
  boot.status,
  'units',
  boot.body?.units?.length,
  'cards',
  boot.body?.cards?.length,
);
console.log('done');
