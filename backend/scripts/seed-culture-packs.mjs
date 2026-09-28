/**
 * Seed Phase 3/4 culture packs: Timkat, Proverbs, Folk song (music),
 * and a steps card with vocab. Idempotent — skips if titles already exist.
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
const am = langs.body.find((l) => l.code === 'am');
if (!am) {
  console.error('no amharic');
  process.exit(1);
}

async function ensureUnit(payload, existingUnits) {
  const found = existingUnits.find((u) => u.title === payload.title);
  if (found) {
    console.log('unit exists', found.id, found.title);
    return found.id;
  }
  const r = await api('/admin/culture-units', 'POST', token, {
    ...payload,
    language_id: am.id,
    is_active: 1,
  });
  console.log('unit', payload.title, r.status, r.body?.id);
  return r.body.id;
}

async function ensureCard(unitId, card) {
  const list = await api(
    `/admin/culture-cards?culture_unit_id=${unitId}`,
    'GET',
    token,
  );
  const existing = (list.body || []).find((c) => c.title === card.title);
  if (existing) {
    console.log('card exists', existing.id, existing.title);
    return existing.id;
  }
  const r = await api('/admin/culture-cards', 'POST', token, {
    ...card,
    culture_unit_id: unitId,
  });
  console.log('card', card.title, r.status, r.body?.id || r.body);
  return r.body?.id;
}

const existingUnits = await api(
  `/admin/culture-units?language_id=${am.id}`,
  'GET',
  token,
);
const units = existingUnits.body || [];

// ── Timkat pack ──────────────────────────────────────────────────────────────
const timkatId = await ensureUnit({
  title: 'ጥምቀት · Timkat',
  subtitle: 'Epiphany — colorful processions and blessing',
  theme: 'holiday',
  color_hex: '#C41E3A',
  dark_hex: '#8B1428',
  icon: 'celebration_rounded',
  sort_order: 1,
}, units);

await ensureCard(timkatId, {
  kind: 'fact',
  title: 'What is Timkat?',
  body: 'Timkat celebrates the baptism of Jesus in the Jordan. Priests carry tabots (replicas of the Ark) while the city fills with white netela, songs, and blessing water.',
  content: {
    en: {
      title: 'What is Timkat?',
      body: 'Timkat celebrates the baptism of Jesus in the Jordan. Priests carry tabots (replicas of the Ark) while the city fills with white netela, songs, and blessing water.',
    },
    so: {
      title: 'Waa maxay Timkat?',
      body: 'Timkat waxay xusaysaa baabtiiska Ciise ee Urdun. Wadaadadu waxay qaadaan tabot, dadkuna wataan dharka cad ee netela.',
    },
    am: {
      title: 'ጥምቀት ምንድን ነው?',
      body: 'ጥምቀት የኢየሱስ በዮርዳኖስ ጥምቀትን ያከብራል። ካህናት ታቦትን ይዘው ይዘዛሉ፣ ከተማዋም በነጭ ነጠላና በመዘምራን ትሞላለች።',
    },
  },
  vocab: [
    { target: 'ጥምቀት', translit: 'timkat', meanings: { en: 'Epiphany / baptism feast', so: 'Ciid baabtiis', am: 'ጥምቀት' } },
    { target: 'ታቦት', translit: 'tabot', meanings: { en: 'Ark replica', so: 'Tabot', am: 'ታቦት' } },
    { target: 'ነጠላ', translit: 'netela', meanings: { en: 'White cotton shawl', so: 'Maro cad', am: 'ነጠላ' } },
  ],
  xp_reward: 10,
  sort_order: 0,
});

await ensureCard(timkatId, {
  kind: 'proverb',
  title: 'ጥቁር ተበጠረ',
  body: 'Even the dark cloud has a silver lining — joy after waiting.',
  translit: 'tikur tebetera',
  content: {
    en: {
      title: 'ጥቁር ተበጠረ',
      body: 'Even the dark cloud has a silver lining — joy after waiting.',
    },
    so: {
      title: 'ጥቁር ተበጠረ',
      body: 'Daruurtu madow waxay leedahay dhalaal — farxad ka dib sugitaan.',
    },
    am: {
      title: 'ጥቁር ተበጠረ',
      body: 'ጥቁር ደመናም የሚያበራ ገጽ አለው — ከጸግታ በኋላ ደስታ።',
    },
  },
  vocab: [],
  xp_reward: 5,
  sort_order: 1,
});

await ensureCard(timkatId, {
  kind: 'steps',
  title: 'How families mark Timkat',
  body: 'A simple walk-through of the feast day.',
  content: {
    en: {
      title: 'How families mark Timkat',
      body: 'A simple walk-through of the feast day.',
    },
    so: {
      title: 'Sida qoysaska u dabaaldegan Timkat',
      body: 'Socod kooban oo maalinta ciida ah.',
    },
    am: {
      title: 'ቤተሰቦች ጥምቀትን እንዴት ያከብራሉ',
      body: 'በዓሉን በአጭር እርምጃዎች።',
    },
  },
  meta: {
    steps: [
      {
        title: { en: 'Dress in white', so: 'Xiran dharka cad', am: 'በነጭ ልበስ' },
        body: {
          en: 'Netela and traditional white clothes mark purity and joy.',
          so: 'Netela iyo dharka cad waxay muujinayaan daahirnimo iyo farxad.',
          am: 'ነጠላና ነጭ ልብስ ንጹሕነትንና ደስታን ይወክላሉ።',
        },
      },
      {
        title: { en: 'Join the procession', so: 'Ku biir socodka', am: 'በዝናቡ ተሳተፍ' },
        body: {
          en: 'Walk with the community as priests carry the tabot.',
          so: 'La soc bulshada wadaadada tabot qaadaan.',
          am: 'ካህናት ታቦትን ሲይዙ ከማህበረሰቡ ጋር ተራመድ።',
        },
      },
      {
        title: { en: 'Receive blessing water', so: 'Qaado biyaha barakada', am: 'የብርሃን ውሃ ተቀበል' },
        body: {
          en: 'Sprinkled water is a blessing for the year ahead.',
          so: 'Biyaha la tufaa waa barako sanadka soo socda.',
          am: 'የሚነጠፋው ውሃ ለሚመጣው ዓመት ብርሃን ነው።',
        },
      },
      {
        title: { en: 'Share a meal', so: 'La wadaag cunto', am: 'ምግብ ተካፈል' },
        body: {
          en: 'Coffee, injera, and visiting neighbors keep the joy going.',
          so: 'Bun, injera, iyo booqashada deriska farxadda sii wadaan.',
          am: 'ቡና፣ እንጀራና የጎረቤት ጉብኝት ደስታውን ያራዝማሉ።',
        },
      },
    ],
  },
  vocab: [
    { target: 'ነጠላ', translit: 'netela', meanings: { en: 'White shawl', so: 'Maro cad', am: 'ነጠላ' } },
    { target: 'ብርሃን', translit: 'birhan', meanings: { en: 'Light / blessing', so: 'Iftiin / barako', am: 'ብርሃን' } },
  ],
  xp_reward: 10,
  sort_order: 2,
});

// ── Proverbs pack ────────────────────────────────────────────────────────────
const proverbsId = await ensureUnit({
  title: 'ምሳሌዎች · Proverbs',
  subtitle: 'Wisdom you can reuse in speech',
  theme: 'proverb',
  color_hex: '#1A5FA8',
  dark_hex: '#0F3D72',
  icon: 'format_quote_rounded',
  sort_order: 2,
}, units);

const proverbs = [
  {
    title: 'ድር ቢያብር አንበሳ ያስር',
    translit: 'dir biyabir anbessa yasir',
    body: 'When spider webs unite, they can tie up a lion — together is strong.',
    so: 'Marka shabakadda lafaha la midoobo, waxay xiri karaan libaax — wadajir way xoog badan tahay.',
  },
  {
    title: 'ቀስ በቀስ እንቁላል በእግሩ ይሄዳል',
    translit: 'qes beqes enkulal be’egru yihedal',
    body: 'Slowly, slowly, an egg will walk — patience moves hard things.',
    so: 'Qorax qorax, ukun lugteeda ayay u socotaa — dulqaadku wax adag ayuu dhaqaajiyaa.',
  },
  {
    title: 'ባሕር የሰው እንባ አይከብድም',
    translit: 'baher yesew enba ayikebdm',
    body: 'The sea is not filled with human tears — keep going after hard days.',
    so: 'Badaha ilmada aadamiga kuma buuxsadaan — sii wado maalmo adag ka dib.',
  },
];

for (let i = 0; i < proverbs.length; i++) {
  const p = proverbs[i];
  await ensureCard(proverbsId, {
    kind: 'proverb',
    title: p.title,
    body: p.body,
    translit: p.translit,
    content: {
      en: { title: p.title, body: p.body },
      so: { title: p.title, body: p.so },
      am: { title: p.title, body: p.body },
    },
    vocab: [],
    xp_reward: 5,
    sort_order: i,
  });
}

// ── Folk song (music) + coffee steps vocab enrichment ────────────────────────
const musicId = await ensureUnit({
  title: 'ዘፈናችን · Folk songs',
  subtitle: 'Public-domain style verses for listening',
  theme: 'music',
  color_hex: '#7B2D8E',
  dark_hex: '#4E1B5C',
  icon: 'music_note_rounded',
  sort_order: 3,
}, units);

await ensureCard(musicId, {
  kind: 'music',
  title: 'Ene negn bilognal',
  body: 'A cheerful welcome verse used in teaching settings (original teaching lyrics — not a commercial recording).',
  translit: 'ene negn bilognal',
  content: {
    en: {
      title: 'Ene negn bilognal',
      body: 'A cheerful welcome verse used in teaching settings (original teaching lyrics — not a commercial recording).',
    },
    so: {
      title: 'Ene negn bilognal',
      body: 'Gabayo soo dhaweyn ah oo lagu barto (asal ahaan barasho — diiwaan ganacsi maaha).',
    },
    am: {
      title: 'እኔ ነኝ ብሎኛል',
      body: 'በትምህርት ዙሪያ የሚጠቀሙ የእንኳን ደህና መጡ ዘፈን (የማስተማር ዜማ — ንግድ ቅጂ አይደለም)።',
    },
  },
  meta: {
    lyrics: [
      {
        line: { en: 'Ene negn bilognal', am: 'እኔ ነኝ ብሎኛል', so: 'Ene negn bilognal' },
        translit: 'ene negn bilognal',
        note: { en: 'I am here and happy to meet you', am: 'አሁን እንተዋወቀናል', so: 'Waa halkan oo farxad leh' },
      },
      {
        line: { en: 'Welcome, welcome, sit with us', am: 'እንኳን ደህና መጡ፣ ከእኛ ጋር ይቀመጡ', so: 'Soo dhawoow, soo dhawoow, nala fadhiiso' },
        translit: 'enkwuan dehna metu',
        note: { en: 'Inviting a guest to join', am: 'እንግዳን ይጋበዛል', so: 'Marti lagu casuumo' },
      },
      {
        line: { en: 'Coffee smells like friendship', am: 'ቡና ጠረን ወዳጅነት ይመስላል', so: 'Buntu wuxuu u uraa saaxiibtinimo' },
        translit: 'buna teren wedajinet yimesilal',
        note: { en: 'Buna as hospitality', am: 'ቡና እንደ እንግዳ እንቅስቃሴ', so: 'Bun sida martisoorka' },
      },
    ],
    license: 'Original teaching lyrics created for etLingo (not a commercial master).',
  },
  vocab: [
    { target: 'እንኳን ደህና መጡ', translit: 'enkwuan dehna metu', meanings: { en: 'Welcome', so: 'Soo dhawoow', am: 'እንኳን ደህና መጡ' } },
    { target: 'ወዳጅ', translit: 'wedaj', meanings: { en: 'Friend', so: 'Saaxiib', am: 'ወዳጅ' } },
  ],
  xp_reward: 5,
  sort_order: 0,
});

// Enrich coffee steps card with vocab if the coffee unit exists
const coffee = units.find((u) => String(u.title || '').includes('ቡና') || String(u.title || '').toLowerCase().includes('coffee'));
if (coffee) {
  const cards = await api(`/admin/culture-cards?culture_unit_id=${coffee.id}`, 'GET', token);
  const steps = (cards.body || []).find((c) => c.kind === 'steps' || c.title === 'Three rounds');
  if (steps) {
    await api(`/admin/culture-cards/${steps.id}`, 'PUT', token, {
      vocab: [
        { target: 'አቦል', translit: 'abol', meanings: { en: 'First cup', so: 'Koobka koowaad', am: 'አቦል' } },
        { target: 'ቶና', translit: 'tona', meanings: { en: 'Second cup', so: 'Koobka labaad', am: 'ቶና' } },
        { target: 'በረካ', translit: 'baraka', meanings: { en: 'Third cup (blessing)', so: 'Koobka saddexaad (barako)', am: 'በረካ' } },
        { target: 'ጀበና', translit: 'jebena', meanings: { en: 'Coffee pot', so: 'Dab-jebena', am: 'ጀበና' } },
      ],
      meta: {
        steps: [
          {
            title: { en: 'Roast the beans', so: 'Dub sababaha', am: 'ጥራጭን አቁማ' },
            body: {
              en: 'Light smoke, green to brown — the smell is the invitation.',
              so: 'Qiiq fudud, cagaar ilaa bunni — urka waa casuumad.',
              am: 'ቀላል ትንፋሽ፣ ከአረንጓዴ ወደ ቡናማ — ሽታው ጥራው ነው።',
            },
          },
          {
            title: { en: 'Brew in the jebena', so: 'Kari dab-jebena', am: 'በጀበና አፍላ' },
            body: {
              en: 'Boil, settle, pour in a thin stream.',
              so: 'Karkari, deji, ku shub durdur khafiif ah.',
              am: 'አፍላ፣ አሳርፋ፣ በቀጭን ፍሳሽ አፍስስ።',
            },
          },
          {
            title: { en: 'Serve abol, tona, baraka', so: 'U qaybi abol, tona, baraka', am: 'አቦል፣ ቶና፣ በረካ አጠግብ' },
            body: {
              en: 'Three small cups. Talk while it is hot.',
              so: 'Saddex koob yar. La hadal markay kulushahay.',
              am: 'ሦስት ትንንሽ ስኒ። ሲሞቅ ተነጋገሩ።',
            },
          },
        ],
      },
    });
    console.log('coffee steps enriched', steps.id);
  }
} else {
  console.log('coffee unit not found — skip steps vocab enrich');
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
const cal = await api('/app/culture/calendar');
console.log('calendar', cal.status, cal.body?.holiday?.name || cal.body?.upcoming?.name || 'no holiday');
console.log('done');
