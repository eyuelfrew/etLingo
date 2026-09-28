/**
 * Seed writing systems + Ge'ez fidel bases + language mappings.
 * Idempotent — safe to re-run.
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
const amLang = (langs.body || []).find((l) => l.code === 'am');
const omLang = (langs.body || []).find((l) => l.code === 'om');
const soLang = (langs.body || []).find((l) => l.code === 'so');

const SCRIPTS = [
  {
    code: 'ethi',
    name: "Ge'ez / Ethiopic",
    native_name: 'ፊደል · Ge’ez',
    direction: 'ltr',
    family: 'Ethiopic',
    sample: 'ሀለሐመ',
    description: 'Ge’ez abugida used for Amharic, Tigrinya, and other Ethiopian languages.',
    sort_order: 0,
    language_id: amLang?.id,
  },
  {
    code: 'latn',
    name: 'Latin',
    native_name: 'Latin',
    direction: 'ltr',
    family: 'Latin',
    sample: 'AaBb',
    description: 'Latin alphabet used for Afaan Oromoo (Qubee), Somali Latin, English.',
    sort_order: 1,
    language_id: omLang?.id,
  },
  {
    code: 'arab',
    name: 'Arabic',
    native_name: 'العربية',
    direction: 'rtl',
    family: 'Arabic',
    sample: 'ابج',
    description: 'Arabic script — liturgical / historical use in the Horn of Africa.',
    sort_order: 2,
  },
  {
    code: 'osma',
    name: 'Osmanya',
    native_name: '𐒖𐒐𐒈𐒑𐒐𐒘',
    direction: 'ltr',
    family: 'Somali',
    sample: '𐒖𐒒',
    description: 'Osmanya script invented for Somali (Cismaaniya).',
    sort_order: 3,
    language_id: soLang?.id,
  },
];

/** Ge'ez 1st-order (hä) base letters — feeds the Fidel trainer. */
const ETHI_BASES = [
  ['ሀ', 'ha', 'hä', 'ha', 'h'],
  ['ለ', 'la', 'lä', 'la', 'l'],
  ['ሐ', 'hha', 'ḥä', 'hha', 'ḥ'],
  ['መ', 'ma', 'mä', 'ma', 'm'],
  ['ሠ', 'sha', 'śä', 'sha', 'ś'],
  ['ረ', 'ra', 'rä', 'ra', 'r'],
  ['ሰ', 'sa', 'sä', 'sa', 's'],
  ['ሸ', 'sha', 'šä', 'sh', 'š'],
  ['ቀ', 'qa', 'qä', 'qa', 'q'],
  ['በ', 'ba', 'bä', 'ba', 'b'],
  ['ቨ', 'va', 'vä', 'va', 'v'],
  ['ተ', 'ta', 'tä', 'ta', 't'],
  ['ቸ', 'cha', 'čä', 'ch', 'č'],
  ['ኀ', 'hha', 'ḫä', 'hha2', 'ḫ'],
  ['ነ', 'na', 'nä', 'na', 'n'],
  ['ኘ', 'nya', 'ñä', 'nya', 'ñ'],
  ['አ', 'a', 'ʾä', 'a', 'ʾ'],
  ['ከ', 'ka', 'kä', 'ka', 'k'],
  ['ኸ', 'xa', 'xä', 'xa', 'x'],
  ['ወ', 'wa', 'wä', 'wa', 'w'],
  ['ዐ', 'aa', 'ʿä', 'aa', 'ʿ'],
  ['ዘ', 'za', 'zä', 'za', 'z'],
  ['ዠ', 'zha', 'žä', 'zha', 'ž'],
  ['የ', 'ya', 'yä', 'ya', 'y'],
  ['ደ', 'da', 'dä', 'da', 'd'],
  ['ጀ', 'ja', 'jä', 'ja', 'j'],
  ['ገ', 'ga', 'gä', 'ga', 'g'],
  ['ጠ', 'tha', 'ṭä', 'tha', 'ṭ'],
  ['ጨ', 'cha', 'č̣ä', 'cha2', 'č̣'],
  ['ጰ', 'pha', 'p̣ä', 'pha', 'p̣'],
  ['ጸ', 'tsa', 'ṣä', 'tsa', 'ṣ'],
  ['ፀ', 'tsha', 'ṣ́ä', 'tsha', 'ṣ́'],
  ['ፈ', 'fa', 'fä', 'fa', 'f'],
  ['ፐ', 'pa', 'pä', 'pa', 'p'],
];

const LATN_BASES = [
  ['A', 'ay', 'ay', 'ay'], ['B', 'bee', 'bee', 'bee'], ['C', 'cee', 'cee', 'cee'],
  ['D', 'dee', 'dee', 'dee'], ['E', 'ee', 'ee', 'ee'], ['F', 'ef', 'ef', 'ef'],
  ['G', 'gee', 'gee', 'gee'], ['H', 'aitch', 'aitch', 'aitch'], ['I', 'eye', 'eye', 'eye'],
  ['J', 'jay', 'jay', 'jay'], ['K', 'kay', 'kay', 'kay'], ['L', 'el', 'el', 'el'],
  ['M', 'em', 'em', 'em'], ['N', 'en', 'en', 'en'], ['O', 'oh', 'oh', 'oh'],
  ['P', 'pee', 'pee', 'pee'], ['Q', 'cue', 'cue', 'cue'], ['R', 'ar', 'ar', 'ar'],
  ['S', 'ess', 'ess', 'ess'], ['T', 'tee', 'tee', 'tee'], ['U', 'you', 'you', 'you'],
  ['V', 'vee', 'vee', 'vee'], ['W', 'doubleyou', 'doubleyou', 'doubleyou'],
  ['X', 'ex', 'ex', 'ex'], ['Y', 'wy', 'wy', 'wy'], ['Z', 'zee', 'zee', 'zee'],
  ['Qa', 'Qaa', 'Qaa', 'Qaa'], ['Xa', 'Xaa', 'Xaa', 'Xaa'], ['Kh', 'Kha', 'Kha', 'Kha'],
  ['Ch', 'Cha', 'Cha', 'Cha'], ['Sh', 'Sha', 'Sha', 'Sha'], ['Dh', 'Dha', 'Dha', 'Dha'],
];

async function ensureScript(payload) {
  const list = await api('/admin/scripts', 'GET', token);
  const found = (list.body || []).find((s) => s.code === payload.code);
  if (found) {
    console.log('script exists', found.id, found.code);
    return found;
  }
  // Language-first: create under a language when language_id is set.
  const langId = payload.language_id;
  const body = { ...payload };
  delete body.language_id;
  const r = langId
    ? await api(`/admin/languages/${langId}/scripts`, 'POST', token, body)
    : await api('/admin/scripts', 'POST', token, body);
  console.log('script', payload.code, r.status, r.body?.id);
  return r.body;
}

async function seedLetters(scriptId, rows, orderName = '') {
  const letters = rows.map(([glyph, name, roman, sound], i) => ({
    glyph,
    name,
    roman,
    sound: sound || roman,
    orderName,
    formIndex: 0,
    sortOrder: i,
  }));
  const r = await api(`/admin/scripts/${scriptId}/letters/bulk`, 'POST', token, {
    letters,
    replace: true,
  });
  console.log('letters', scriptId, r.status, r.body?.imported);
}

async function mapLang(languageCode, scriptId, isPrimary, role) {
  const langs = await api('/admin/languages', 'GET', token);
  const lang = (langs.body || []).find((l) => l.code === languageCode);
  if (!lang) {
    console.log('skip map, no lang', languageCode);
    return;
  }
  const maps = await api(`/admin/language-scripts?language_id=${lang.id}`, 'GET', token);
  const exists = (maps.body || []).find((m) => m.scriptId === scriptId);
  if (exists) {
    console.log('map exists', languageCode, scriptId);
    return;
  }
  const r = await api('/admin/language-scripts', 'POST', token, {
    language_id: lang.id,
    script_id: scriptId,
    is_primary: isPrimary,
    role,
  });
  console.log('map', languageCode, '→', scriptId, r.status);
}

const ethi = await ensureScript(SCRIPTS[0]);
const latn = await ensureScript(SCRIPTS[1]);
const arab = await ensureScript(SCRIPTS[2]);
const osma = await ensureScript(SCRIPTS[3]);

if (ethi?.id) await seedLetters(ethi.id, ETHI_BASES, 'h');
if (latn?.id) await seedLetters(latn.id, LATN_BASES, '');

// Primary writing systems for Ethiopian courses
if (ethi?.id) {
  await mapLang('am', ethi.id, true, 'primary');
  await mapLang('ti', ethi.id, true, 'primary');
}
if (latn?.id) {
  await mapLang('om', latn.id, true, 'primary'); // Qubee
  await mapLang('so', latn.id, true, 'primary'); // Somali Latin
  await mapLang('en', latn.id, true, 'primary');
}
if (arab?.id) {
  await mapLang('so', arab.id, false, 'historical');
  await mapLang('am', arab.id, false, 'liturgical');
}
if (osma?.id) {
  await mapLang('so', osma.id, false, 'historical');
}

const boot = await api('/app/scripts?lang=am');
console.log(
  'app am scripts',
  boot.status,
  (boot.body?.scripts || []).map((s) => `${s.code}:${s.letters.length}`).join(', '),
);
console.log('done');
