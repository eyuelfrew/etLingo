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
    return JSON.parse(text);
  } catch {
    return { raw: text, status: r.status };
  }
}

const login = await api('/auth/login', 'POST', null, {
  email: 'admin@etlang.app',
  password: 'admin123',
});
if (!login.token) {
  console.error('login failed', login);
  process.exit(1);
}
const token = login.token;
const call = (p, m = 'GET', b) => api(p, m, token, b);

const langs = await call('/admin/languages');
const am = langs.find((l) => l.code === 'am');
if (!am) {
  console.error('Amharic language missing');
  process.exit(1);
}

const units = await call('/admin/units?language_id=' + am.id);
const lessonsAll = await call('/admin/lessons');
const amUnits = units.filter((u) => u.language_id === am.id);
let u1 = amUnits[0];
if (!u1) {
  u1 = await call('/admin/units', 'POST', {
    language_id: am.id,
    title: 'ክፍል 1 · ሰላም Greetings',
    subtitle: 'Say hello like a habesha',
    color_hex: '#078930',
    dark_hex: '#056B24',
    icon: 'waving_hand_rounded',
    sort_order: 0,
  });
  console.log('created unit', u1.id);
} else {
  await call('/admin/units/' + u1.id, 'PUT', {
    title: 'ክፍል 1 · ሰላም Greetings',
    subtitle: 'Say hello like a habesha',
    color_hex: '#078930',
    dark_hex: '#056B24',
  });
  console.log('updated unit', u1.id);
}

const amUnitIds = new Set(units.filter((u) => u.language_id === am.id).map((u) => u.id));
const amLessons = lessonsAll.filter((l) => amUnitIds.has(l.unit_id));

const teach1 = [
  { target: 'ሰላም', translit: 'selam', meaning: 'Hello / Peace', meanings: { en: 'Hello / Peace', am: 'ሰላም' }, audioUrl: '' },
  { target: 'አመሰግናለሁ', translit: 'ameseginalehu', meaning: 'Thank you', meanings: { en: 'Thank you', am: 'አመሰግናለሁ' }, audioUrl: '' },
  { target: 'ደህና ሁን', translit: 'dehna hun', meaning: 'Goodbye', meanings: { en: 'Goodbye', am: 'ደህና ሁን' }, audioUrl: '' },
];
const teach2 = [
  { target: 'እንዴት ነህ?', translit: 'indet neh?', meaning: 'How are you? (to a man)', meanings: { en: 'How are you? (to a man)', am: 'እንዴት ነህ?' }, audioUrl: '' },
  { target: 'ደህና ነኝ', translit: 'dehna negn', meaning: 'I am fine', meanings: { en: 'I am fine', am: 'ደህና ነኝ' }, audioUrl: '' },
  { target: 'ስሜ ... ነው', translit: 'sime ... new', meaning: 'My name is...', meanings: { en: 'My name is...', am: 'ስሜ ... ነው' }, audioUrl: '' },
];

async function ensureLesson(title, sort, teach, xp, boss) {
  let l = amLessons.find((x) => x.title === title);
  if (!l) {
    l = await call('/admin/lessons', 'POST', {
      unit_id: u1.id,
      title,
      is_boss: boss ? 1 : 0,
      xp_reward: xp,
      sort_order: sort,
      teach_content: teach,
    });
    console.log('created lesson', l.id, l.title);
  } else {
    await call('/admin/lessons/' + l.id, 'PUT', {
      teach_content: teach,
      xp_reward: xp,
      is_boss: boss ? 1 : 0,
      sort_order: sort,
    });
    console.log('updated lesson', l.id, l.title);
  }
  return l;
}

const l1 = await ensureLesson('First words', 0, teach1, 10, false);
const l2 = await ensureLesson('How are you?', 1, teach2, 10, false);
const l3 = await ensureLesson('Unit 1 review', 2, teach1, 15, true);

const questions = await call('/admin/questions');
const byLesson = (id) => questions.filter((q) => q.lesson_id === id);

async function addQ(lessonId, body) {
  const r = await call('/admin/questions', 'POST', { lesson_id: lessonId, ...body });
  console.log('question', lessonId, r.id, r.kind);
}

if (byLesson(l1.id).length === 0) {
  await addQ(l1.id, {
    kind: 'mcq',
    prompt: "Which one means Hello?",
    sub_prompt: '',
    hint: '',
    options: [{ label: 'ሰላም' }, { label: 'ውሃ' }, { label: 'ቡና' }, { label: 'ቤት' }],
    answer_index: 0,
    match_left: null,
    match_right: null,
    audio_url: '',
    sort_order: 0,
    content: { en: { prompt: "Which one means Hello?" } },
  });
  await addQ(l1.id, {
    kind: 'mcq',
    prompt: 'What does it mean?',
    sub_prompt: 'ሰላም',
    hint: 'se·lam',
    options: [{ label: 'Peace / Hello' }, { label: 'Water' }, { label: 'Coffee' }, { label: 'House' }],
    answer_index: 0,
    sort_order: 1,
    content: { en: { prompt: 'What does it mean?', subPrompt: 'ሰላም', hint: 'se·lam' } },
  });
  await addQ(l1.id, {
    kind: 'match',
    prompt: 'Match the pairs',
    options: null,
    answer_index: -1,
    match_left: ['ሰላም', 'አመሰግናለሁ', 'ደህና ሁን'],
    match_right: ['Hello', 'Thank you', 'Goodbye'],
    sort_order: 2,
    content: { en: { prompt: 'Match the pairs' } },
  });
  await addQ(l1.id, {
    kind: 'fill',
    prompt: 'Thank you in Amharic',
    sub_prompt: 'Thank you → ___',
    options: [{ label: 'አመሰግናለሁ' }, { label: 'ደህና ሁን' }, { label: 'እንዴት ነህ' }],
    answer_index: 0,
    sort_order: 3,
    content: { en: { prompt: 'Thank you in Amharic', subPrompt: 'Thank you → ___' } },
  });
}

if (byLesson(l2.id).length === 0) {
  await addQ(l2.id, {
    kind: 'mcq',
    prompt: 'Ask how are you to a man',
    sub_prompt: '',
    options: [{ label: 'እንዴት ነህ?' }, { label: 'ሰላም' }, { label: 'ቡና' }, { label: 'ደህና ሁን' }],
    answer_index: 0,
    sort_order: 0,
    content: { en: { prompt: 'Ask how are you to a man' } },
  });
  await addQ(l2.id, {
    kind: 'mcq',
    prompt: 'I am fine',
    sub_prompt: 'ደህና ነኝ',
    options: [{ label: 'I am fine' }, { label: 'I am hungry' }, { label: 'Good night' }, { label: 'Thank you' }],
    answer_index: 0,
    sort_order: 1,
    content: { en: { prompt: 'I am fine', subPrompt: 'ደህና ነኝ' } },
  });
  await addQ(l2.id, {
    kind: 'fill',
    prompt: 'My name is',
    sub_prompt: 'My name is → ___',
    options: [{ label: 'ስሜ' }, { label: 'ቡና' }, { label: 'ውሃ' }],
    answer_index: 0,
    sort_order: 2,
    content: { en: { prompt: 'My name is', subPrompt: 'My name is → ___' } },
  });
}

if (byLesson(l3.id).length === 0) {
  await addQ(l3.id, {
    kind: 'match',
    prompt: 'Boss review — match them',
    options: null,
    answer_index: -1,
    match_left: ['ሰላም', 'አመሰግናለሁ', 'እንዴት ነህ?'],
    match_right: ['Hello', 'Thank you', 'How are you?'],
    sort_order: 0,
    content: { en: { prompt: 'Boss review — match them' } },
  });
  await addQ(l3.id, {
    kind: 'mcq',
    prompt: 'Goodbye',
    sub_prompt: '',
    options: [{ label: 'ደህና ሁን' }, { label: 'ሰላም' }, { label: 'ስሜ' }, { label: 'ቡና' }],
    answer_index: 0,
    sort_order: 1,
    content: { en: { prompt: 'Goodbye' } },
  });
}

const phrases = await call('/admin/phrases?language_id=' + am.id);
if (!Array.isArray(phrases) || phrases.length === 0) {
  const P = [
    ['ሰላም', 'selam', 'Hello', 'Basics'],
    ['አመሰግናለሁ', 'ameseginalehu', 'Thank you', 'Basics'],
    ['ደህና ሁን', 'dehna hun', 'Goodbye', 'Basics'],
    ['እንዴት ነህ?', 'indet neh?', 'How are you?', 'Basics'],
    ['ደህና ነኝ', 'dehna negn', 'I am fine', 'Basics'],
    ['ቡና', 'buna', 'Coffee', 'Culture'],
    ['እንጀራ', 'injera', 'Injera', 'Culture'],
    ['ጤፍ', 'tef', 'Teff', 'Culture'],
  ];
  for (let i = 0; i < P.length; i++) {
    const [target, translit, meaning, category] = P[i];
    await call('/admin/phrases', 'POST', {
      language_id: am.id,
      target,
      translit,
      meaning,
      category,
      sort_order: i,
      audio_url: '',
    });
  }
  console.log('seeded phrases', P.length);
}

const boot = await api('/app/bootstrap/am');
console.log(
  'bootstrap',
  'units',
  boot.units?.length,
  'lessons',
  boot.lessons?.length,
  'questions',
  boot.questions?.length,
  'phrases',
  boot.phrases?.length,
);
console.log('done');
