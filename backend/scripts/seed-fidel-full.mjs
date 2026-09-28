/**
 * Full Ge'ez (Ethiopic) fidel: 7 orders × family rows (+ labiovelar 8th where standard).
 * order_name = family key (h, l, m…)
 * form_index = 0..6 vowel order (ä u i a e ə o); 7 = labiovelar -wa
 *
 * Seed: node scripts/seed-fidel-full.mjs  (replaces ethi letters)
 */
const base = 'http://localhost:5050/api/v1';

const VOWELS = [
  { i: 0, am: '1', rom: 'ä', sound: 'e', label: '1st · ä' },
  { i: 1, am: '2', rom: 'u', sound: 'u', label: '2nd · u' },
  { i: 2, am: '3', rom: 'i', sound: 'i', label: '3rd · i' },
  { i: 3, am: '4', rom: 'a', sound: 'aa', label: '4th · a' },
  { i: 4, am: '5', rom: 'e', sound: 'ee', label: '5th · e' },
  { i: 5, am: '6', rom: 'ə', sound: 'h', label: '6th · ə' },
  { i: 6, am: '7', rom: 'o', sound: 'o', label: '7th · o' },
];

/**
 * [familyKey, consonantSound, glyph1..glyph7, glyph8Labio?]
 * glyph order matches VOWELS (0–6). Optional 8th = -wa labiovelar form.
 */
const FAMILIES = [
  ['h', 'h', 'ሀ', 'ሁ', 'ሂ', 'ሃ', 'ሄ', 'ህ', 'ሆ', 'ሇ'],
  ['l', 'l', 'ለ', 'ሉ', 'ሊ', 'ላ', 'ሌ', 'ል', 'ሎ', 'ሏ'],
  ['ḥ', 'hh', 'ሐ', 'ሑ', 'ሒ', 'ሓ', 'ሔ', 'ሕ', 'ሖ', 'ሗ'],
  ['m', 'm', 'መ', 'ሙ', 'ሚ', 'ማ', 'ሜ', 'ም', 'ሞ', 'ሟ'],
  ['ś', 'sh', 'ሠ', 'ሡ', 'ሢ', 'ሣ', 'ሤ', 'ሥ', 'ሦ', 'ሧ'],
  ['r', 'r', 'ረ', 'ሩ', 'ሪ', 'ራ', 'ሬ', 'ር', 'ሮ', 'ሯ'],
  ['s', 's', 'ሰ', 'ሱ', 'ሲ', 'ሳ', 'ሴ', 'ስ', 'ሶ', 'ሷ'],
  ['š', 'sh', 'ሸ', 'ሹ', 'ሺ', 'ሻ', 'ሼ', 'ሽ', 'ሾ', 'ሿ'],
  ['q', 'q', 'ቀ', 'ቁ', 'ቂ', 'ቃ', 'ቄ', 'ቅ', 'ቆ', 'ቇ'],
  ['b', 'b', 'በ', 'ቡ', 'ቢ', 'ባ', 'ቤ', 'ብ', 'ቦ', 'ቧ'],
  ['v', 'v', 'ቨ', 'ቩ', 'ቪ', 'ቫ', 'ቬ', 'ቭ', 'ቮ', 'ቯ'],
  ['t', 't', 'ተ', 'ቱ', 'ቲ', 'ታ', 'ቴ', 'ት', 'ቶ', 'ቷ'],
  ['č', 'ch', 'ቸ', 'ቹ', 'ቺ', 'ቻ', 'ቼ', 'ች', 'ቾ', 'ቿ'],
  ['ḫ', 'hh', 'ኀ', 'ኁ', 'ኂ', 'ኃ', 'ኄ', 'ኅ', 'ኆ', 'ኇ'],
  ['n', 'n', 'ነ', 'ኑ', 'ኒ', 'ና', 'ኔ', 'ን', 'ኖ', 'ኗ'],
  ['ñ', 'ny', 'ኘ', 'ኙ', 'ኚ', 'ኛ', 'ኜ', 'ኝ', 'ኞ', 'ኟ'],
  ['ʾ', 'a', 'አ', 'ኡ', 'ኢ', 'ኣ', 'ኤ', 'እ', 'ኦ', 'ኧ'],
  ['k', 'k', 'ከ', 'ኩ', 'ኪ', 'ካ', 'ኬ', 'ክ', 'ኮ', 'ኯ'],
  ['x', 'x', 'ኸ', 'ኹ', 'ኺ', 'ኻ', 'ኼ', 'ኽ', 'ኾ', 'ዀ'],
  ['w', 'w', 'ወ', 'ዉ', 'ዊ', 'ዋ', 'ዌ', 'ው', 'ዎ', 'ዏ'],
  ['ʿ', 'aa', 'ዐ', 'ዑ', 'ዒ', 'ዓ', 'ዔ', 'ዕ', 'ዖ', ''],
  ['z', 'z', 'ዘ', 'ዙ', 'ዚ', 'ዛ', 'ዜ', 'ዝ', 'ዞ', 'ዟ'],
  ['ž', 'zh', 'ዠ', 'ዡ', 'ዢ', 'ዣ', 'ዤ', 'ዥ', 'ዦ', 'ዧ'],
  ['y', 'y', 'የ', 'ዩ', 'ዪ', 'ያ', 'ዬ', 'ይ', 'ዮ', 'ዯ'],
  ['d', 'd', 'ደ', 'ዱ', 'ዲ', 'ዳ', 'ዴ', 'ድ', 'ዶ', 'ዷ'],
  ['j', 'j', 'ጀ', 'ጁ', 'ጂ', 'ጃ', 'ጄ', 'ጅ', 'ጆ', 'ጇ'],
  ['g', 'g', 'ገ', 'ጉ', 'ጊ', 'ጋ', 'ጌ', 'ግ', 'ጎ', 'ጏ'],
  ['ṭ', 'th', 'ጠ', 'ጡ', 'ጢ', 'ጣ', 'ጤ', 'ጥ', 'ጦ', 'ጧ'],
  ['č̣', 'ch', 'ጨ', 'ጩ', 'ጪ', 'ጫ', 'ጬ', 'ጭ', 'ጮ', 'ጯ'],
  ['p̣', 'ph', 'ጰ', 'ጱ', 'ጲ', 'ጳ', 'ጴ', 'ጵ', 'ጶ', 'ጷ'],
  ['ṣ', 'ts', 'ጸ', 'ጹ', 'ጺ', 'ጻ', 'ጼ', 'ጽ', 'ጾ', 'ጿ'],
  ['ṣ́', 'ts', 'ፀ', 'ፁ', 'ፂ', 'ፃ', 'ፄ', 'ፅ', 'ፆ', 'ፇ'],
  ['f', 'f', 'ፈ', 'ፉ', 'ፊ', 'ፋ', 'ፌ', 'ፍ', 'ፎ', 'ፏ'],
  ['p', 'p', 'ፐ', 'ፑ', 'ፒ', 'ፓ', 'ፔ', 'ፕ', 'ፖ', 'ፗ'],
];

function buildLetters() {
  const out = [];
  let sort = 0;
  for (let f = 0; f < FAMILIES.length; f++) {
    const row = FAMILIES[f];
    const [family, cons] = row;
    const glyphs = row.slice(2);
    for (let form = 0; form < 7; form++) {
      const glyph = glyphs[form];
      if (!glyph) continue;
      const v = VOWELS[form];
      const roman = form === 5 ? `${cons}` : `${cons}${v.rom}`;
      // Prefer readable roman: hä, hu, hi, ha, he, h, ho
      const pretty =
        form === 0
          ? `${cons === 'a' || cons === 'aa' ? cons : cons}ä`
          : form === 5
            ? `${cons}ə`
            : `${cons}${v.rom}`;
      out.push({
        glyph,
        name: `${family} ${v.label}`,
        roman: pretty,
        sound: form === 5 ? `${cons}` : `${cons}${v.sound === 'h' ? '' : v.sound}`,
        orderName: family,
        formIndex: form,
        sortOrder: sort++,
        notes: v.label,
      });
    }
    const labio = glyphs[7];
    if (labio) {
      out.push({
        glyph: labio,
        name: `${family} 8th · wa`,
        roman: `${cons}wa`,
        sound: `${cons}wa`,
        orderName: family,
        formIndex: 7,
        sortOrder: sort++,
        notes: 'Labiovelar (wa form)',
      });
    }
  }
  // Cleaner sounds per form
  for (const l of out) {
    const v = VOWELS[l.formIndex];
    if (l.formIndex === 7) continue;
    const cons = l.orderName;
    const map = {
      h: 'h',
      l: 'l',
      ḥ: 'hh',
      m: 'm',
      ś: 'sh',
      r: 'r',
      s: 's',
      š: 'sh',
      q: 'q',
      b: 'b',
      v: 'v',
      t: 't',
      č: 'ch',
      ḫ: 'hh',
      n: 'n',
      ñ: 'ny',
      ʾ: 'a',
      k: 'k',
      x: 'x',
      w: 'w',
      ʿ: 'aa',
      z: 'z',
      ž: 'zh',
      y: 'y',
      d: 'd',
      j: 'j',
      g: 'g',
      ṭ: 'th',
      'č̣': 'ch',
      'p̣': 'ph',
      ṣ: 'ts',
      'ṣ́': 'ts',
      f: 'f',
      p: 'p',
    };
    const c = map[cons] || cons;
    const vs = ['', 'u', 'i', 'aa', 'ee', '', 'o'];
    l.sound = `${c}${vs[l.formIndex] || ''}`;
    l.roman = `${c}${['ä', 'u', 'i', 'a', 'e', 'ə', 'o'][l.formIndex]}`;
  }
  return out;
}

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

const scripts = await api('/admin/scripts', 'GET', token);
const ethi = (scripts.body || []).find((s) => s.code === 'ethi');
if (!ethi) {
  console.error('ethi script not found — run seed-scripts first');
  process.exit(1);
}

const letters = buildLetters();
console.log('built', letters.length, 'letters,', new Set(letters.map((l) => l.orderName)).size, 'families');

const r = await api(`/admin/scripts/${ethi.id}/letters/bulk`, 'POST', token, {
  replace: true,
  letters,
});
console.log('import', r.status, r.body?.imported);

const check = await api(`/admin/scripts/${ethi.id}/letters/bulk`, 'GET');
const app = await api('/app/scripts/ethi/letters');
const list = app.body?.letters || [];
console.log('app letters', list.length);
console.log('sample h-family', list.filter((l) => l.orderName === 'h').map((l) => l.glyph).join(' '));
console.log('done');
