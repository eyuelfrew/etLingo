/**
 * Seed topic word packs: Animals, Food, Colors (Amharic + EN/SO meanings).
 * Idempotent by category slug.
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

const langs = await api('/admin/languages', 'GET', token);
const am = (langs.body || []).find((l) => l.code === 'am');
if (!am) {
  console.error('no amharic');
  process.exit(1);
}

const PACKS = [
  {
    slug: 'animals',
    title: 'Animals',
    native_title: 'እንስሳት',
    emoji: '🦁',
    color_hex: '#C47B1A',
    description: 'Everyday animals — name, sound, and where they live.',
    sort_order: 0,
    words: [
      { target: 'አውሬ', translit: 'awere', meaning: 'Animal', meanings: { en: 'Animal', so: 'Xayawaan', am: 'አውሬ' } },
      { target: 'ውሻ', translit: 'wesha', meaning: 'Dog', meanings: { en: 'Dog', so: 'Eeyo', am: 'ውሻ' } },
      { target: 'ድመት', translit: 'dmet', meaning: 'Cat', meanings: { en: 'Cat', so: 'Bisad', am: 'ድመት' } },
      { target: 'በሮ', translit: 'bero', meaning: 'Horse', meanings: { en: 'Horse', so: 'Faras', am: 'በሮ' } },
      { target: 'ላም', translit: 'lam', meaning: 'Cow', meanings: { en: 'Cow', so: 'Sacad', am: 'ላም' } },
      { target: 'ፍየል', translit: 'fiyel', meaning: 'Goat', meanings: { en: 'Goat', so: 'Ri', am: 'ፍየል' } },
      { target: 'በግ', translit: 'beg', meaning: 'Sheep', meanings: { en: 'Sheep', so: 'Ido', am: 'በግ' } },
      { target: 'ዶሮ', translit: 'doro', meaning: 'Chicken', meanings: { en: 'Chicken', so: 'Dooro', am: 'ዶሮ' } },
      { target: 'አንበሳ', translit: 'anbessa', meaning: 'Lion', meanings: { en: 'Lion', so: 'Libaax', am: 'አንበሳ' } },
      { target: 'ዝሆን', translit: 'zihon', meaning: 'Elephant', meanings: { en: 'Elephant', so: 'Maroodi', am: 'ዝሆን' } },
      { target: 'ነብር', translit: 'nebr', meaning: 'Leopard', meanings: { en: 'Leopard', so: 'Libaax-dhibaatada', am: 'ነብር' } },
      { target: 'ጉንደት', translit: 'gundet', meaning: 'Monkey', meanings: { en: 'Monkey', so: 'Dayuur', am: 'ጉንደት' } },
      { target: 'ኣዳማ', translit: 'adama', meaning: 'Zebra (lit. animal of Adama)', meanings: { en: 'Zebra', so: 'Faras-duureed', am: 'ኣዳማ' } },
      { target: 'ዶሮ ማር', translit: 'doro mar', meaning: 'Bee', meanings: { en: 'Bee', so: 'Shinni', am: 'ዶሮ ማር' } },
      { target: 'በራ', translit: 'bera', meaning: 'Fly (insect)', meanings: { en: 'Fly', so: 'Duul', am: 'በራ' } },
      { target: 'ሳምሳም', translit: 'samsam', meaning: 'Ant', meanings: { en: 'Ant', so: 'Ciidda', am: 'ሳምሳም' } },
    ],
  },
  {
    slug: 'food',
    title: 'Food & drink',
    native_title: 'ምግብና መጠጥ',
    emoji: '🍛',
    color_hex: '#B54A1E',
    description: 'Meals, coffee, and shared plates.',
    sort_order: 1,
    words: [
      { target: 'ምግብ', translit: 'migib', meaning: 'Food', meanings: { en: 'Food', so: 'Cunto', am: 'ምግብ' } },
      { target: 'እንጀራ', translit: 'injera', meaning: 'Injera flatbread', meanings: { en: 'Injera', so: 'Injera', am: 'እንጀራ' } },
      { target: 'ወጥ', translit: 'wot', meaning: 'Stew / wot', meanings: { en: 'Stew', so: 'Maraq', am: 'ወጥ' } },
      { target: 'በያይነት', translit: 'beyaynet', meaning: 'Mixed veggie plate', meanings: { en: 'Mixed platter', so: 'Cunto isku dhafan', am: 'በያይነት' } },
      { target: 'ቡና', translit: 'buna', meaning: 'Coffee', meanings: { en: 'Coffee', so: 'Bun', am: 'ቡና' } },
      { target: 'ውሃ', translit: 'wiha', meaning: 'Water', meanings: { en: 'Water', so: 'Biyaha', am: 'ውሃ' } },
      { target: 'ንብ ማር', translit: 'nib mar', meaning: 'Honey', meanings: { en: 'Honey', so: 'Malab', am: 'ንብ ማር' } },
      { target: 'ብርቱካን', translit: 'bertukan', meaning: 'Orange', meanings: { en: 'Orange', so: 'Liin', am: 'ብርቱካን' } },
      { target: 'ቲማቲም', translit: 'timatim', meaning: 'Tomato', meanings: { en: 'Tomato', so: 'Yaanyo', am: 'ቲማቲም' } },
      { target: 'ድንች', translit: 'dnch', meaning: 'Potato', meanings: { en: 'Potato', so: 'Bataato', am: 'ድንች' } },
      { target: 'ጤፍ', translit: 'tef', meaning: 'Teff', meanings: { en: 'Teff grain', so: 'Teff', am: 'ጤፍ' } },
      { target: 'ስንዴ', translit: 'snde', meaning: 'Wheat', meanings: { en: 'Wheat', so: 'Galley', am: 'ስንዴ' } },
    ],
  },
  {
    slug: 'colors',
    title: 'Colors',
    native_title: 'ቀለማት',
    emoji: '🎨',
    color_hex: '#2B5FCC',
    description: 'Name the colors around you.',
    sort_order: 2,
    words: [
      { target: 'ቀይ', translit: 'key', meaning: 'Red', meanings: { en: 'Red', so: 'Cas', am: 'ቀይ' } },
      { target: 'ቢጫ', translit: 'bicha', meaning: 'Yellow', meanings: { en: 'Yellow', so: 'Jaalle', am: 'ቢጫ' } },
      { target: 'አረንጓዴ', translit: 'arengwade', meaning: 'Green', meanings: { en: 'Green', so: 'Cagaar', am: 'አረንጓዴ' } },
      { target: 'ሰማያዊ', translit: 'semayawi', meaning: 'Blue', meanings: { en: 'Blue', so: 'Buluu', am: 'ሰማያዊ' } },
      { target: 'ነጭ', translit: 'nech', meaning: 'White', meanings: { en: 'White', so: 'Caddaan', am: 'ነጭ' } },
      { target: 'ጥቁር', translit: 'tikur', meaning: 'Black', meanings: { en: 'Black', so: 'Madow', am: 'ጥቁር' } },
      { target: 'ቡናማ', translit: 'bunama', meaning: 'Brown', meanings: { en: 'Brown', so: 'Bunni', am: 'ቡናማ' } },
      { target: 'ብርታት', translit: 'brtat', meaning: 'Purple / violet', meanings: { en: 'Purple', so: 'Guduud', am: 'ብርታት' } },
    ],
  },
];

async function ensureCategory(pack) {
  const list = await api(`/admin/topic-categories?language_id=${am.id}`, 'GET', token);
  const found = (list.body || []).find((c) => c.slug === pack.slug);
  if (found) {
    console.log('category exists', found.id, found.slug);
    return found.id;
  }
  const r = await api('/admin/topic-categories', 'POST', token, {
    ...pack,
    language_id: am.id,
    is_active: 1,
  });
  console.log('category', pack.slug, r.status, r.body?.id);
  return r.body.id;
}

for (const pack of PACKS) {
  const id = await ensureCategory(pack);
  if (!id) continue;
  const existing = await api(`/admin/topic-words?category_id=${id}`, 'GET', token);
  if ((existing.body || []).length) {
    console.log('words exist', pack.slug, existing.body.length);
    continue;
  }
  const r = await api(`/admin/topic-categories/${id}/words/bulk`, 'POST', token, {
    replace: true,
    words: pack.words.map((w, i) => ({ ...w, sortOrder: i })),
  });
  console.log('words', pack.slug, r.status, r.body?.imported);
}

const boot = await api(`/app/topics/${am.code}?base=en`);
console.log(
  'app topics',
  boot.status,
  (boot.body?.categories || [])
    .map((c) => `${c.slug}:${c.wordCount}`)
    .join(', '),
);
console.log('done');
