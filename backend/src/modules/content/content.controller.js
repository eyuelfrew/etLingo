import { Language, Unit, Lesson, Question, Phrase, BaseLanguage } from './content.models.js';
// Explicit cross-module handover: publishing content announces itself to
// learners through the notifications module's service (never its tables).
import { announceNewContent, isPublished } from '../notifications/notifications.events.js';

function pick(obj, fields) {
  const out = {};
  for (const f of fields) if (obj[f] !== undefined) out[f] = obj[f];
  return out;
}

function makeCrud(Model, fields, jsonFields = [], hooks = {}) {
  return {
    async list(req, res) {
      const where = {};
      for (const f of fields) if (req.query[f] !== undefined) where[f] = req.query[f];
      const rows = await Model.findAll({
        where: Object.keys(where).length ? where : undefined,
        order: [['sort_order', 'ASC'], ['id', 'ASC']],
      });
      res.json(rows);
    },

    async getOne(req, res) {
      const row = await Model.findByPk(req.params.id);
      if (!row) return res.status(404).json({ error: 'not found' });
      res.json(row);
    },

    async create(req, res) {
      const data = pick(req.body, [...fields, ...jsonFields]);
      const row = await Model.create(data);
      // Announce learner-facing publications without blocking the response.
      if (hooks.afterCreate) {
        Promise.resolve(hooks.afterCreate(row)).catch((err) =>
          console.error(`[content] publish announcement failed: ${err.message}`));
      }
      res.status(201).json(row);
    },

    async update(req, res) {
      const row = await Model.findByPk(req.params.id);
      if (!row) return res.status(404).json({ error: 'not found' });
      const data = pick(req.body, [...fields, ...jsonFields]);
      await row.update(data);
      res.json(row);
    },

    async remove(req, res) {
      const row = await Model.findByPk(req.params.id);
      if (!row) return res.status(404).json({ error: 'not found' });
      await row.destroy();
      res.status(204).end();
    },
  };
}

const languages = makeCrud(Language,
  ['code', 'name', 'native_name', 'script_preview', 'speakers', 'region', 'color_hex', 'dark_hex', 'hello_target', 'hello_meaning', 'icon', 'sort_order', 'is_active'],
  [],
  {
    // New course went live → tell every learner (respects `new_content` opt-outs).
    afterCreate: async (row) => {
      if (!isPublished(row)) return;
      const name = row.native_name || row.name;
      await announceNewContent({
        title: `New language available: ${name}`,
        body: `${name} (${row.name}) just landed on EtLingo. ${row.hello_meaning ? `Start with "${row.hello_target || ''}" — ${row.hello_meaning}.` : 'Open the app to start your first lesson.'}`.trim(),
      });
    },
  },
);

const units = makeCrud(Unit, ['language_id', 'title', 'subtitle', 'color_hex', 'dark_hex', 'icon', 'sort_order'], ['teach_content']);

const lessons = makeCrud(Lesson, ['unit_id', 'title', 'is_boss', 'xp_reward', 'sort_order'], ['teach_content', 'resources'], {
  // New lesson published → announce it with its language for context.
  afterCreate: async (row) => {
    const unit = await Unit.findByPk(row.unit_id);
    const lang = unit ? await Language.findByPk(unit.language_id) : null;
    const langName = lang ? (lang.native_name || lang.name) : '';
    await announceNewContent({
      title: `New lesson: ${row.title}`,
      body: langName
        ? `A fresh lesson "${row.title}" is now live in the ${langName} course. Earn ${row.xp_reward ?? 10} XP — jump in!`
        : `A fresh lesson "${row.title}" is now live. Jump in and earn ${row.xp_reward ?? 10} XP!`,
    });
  },
});
const questions = makeCrud(Question,
  ['lesson_id', 'kind', 'prompt', 'sub_prompt', 'hint', 'options', 'answer_index', 'match_left', 'match_right', 'audio_url', 'sort_order'],
  ['options', 'match_left', 'match_right', 'content'],
);
const phrases = makeCrud(Phrase, ['language_id', 'target', 'translit', 'meaning', 'category', 'audio_url', 'sort_order']);

export async function dashboardStats(_req, res) {
  const [langCount, unitCount, lessonCount, phraseCount, questionCount] = await Promise.all([
    Language.count(), Unit.count(), Lesson.count(), Phrase.count(), Question.count(),
  ]);
  res.json({
    languages: langCount, units: unitCount, lessons: lessonCount,
    phrases: phraseCount, questions: questionCount,
  });
}

const baseLanguages = makeCrud(BaseLanguage, ['code', 'name', 'native_name', 'is_active', 'sort_order']);

export { languages, units, lessons, questions, phrases, baseLanguages };

// ── Public app-facing content ─────────────────────────────────────────────────

export const appLanguages = async (req, res) => {
  const rows = await Language.findAll({
    where: { is_active: true },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });

  res.json(rows.map(l => {
    const j = l.toJSON();
    return {
      id: j.code,
      name: j.name,
      nativeName: j.native_name,
      scriptPreview: j.script_preview,
      speakers: j.speakers,
      region: j.region,
      colorHex: j.color_hex,
      darkHex: j.dark_hex,
      helloTarget: j.hello_target,
      helloMeaning: j.hello_meaning,
      icon: j.icon,
    };
  }));
};

export async function bootstrap(req, res) {
  const { code } = req.params;
  const lang = await Language.findOne({ where: { code, is_active: true } });
  if (!lang) return res.status(404).json({ error: 'language not found' });

  const unitsList = await Unit.findAll({
    where: { language_id: lang.id },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });

  const unitIds = unitsList.map(u => u.id);
  const lessonsList = unitIds.length
    ? await Lesson.findAll({ where: { unit_id: unitIds }, order: [['sort_order', 'ASC'], ['id', 'ASC']] })
    : [];

  const lessonIds = lessonsList.map(l => l.id);
  const questionsList = lessonIds.length
    ? await Question.findAll({ where: { lesson_id: lessonIds }, order: [['sort_order', 'ASC'], ['id', 'ASC']] })
    : [];

  const phrasesList = await Phrase.findAll({
    where: { language_id: lang.id },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });

  const j = lang.toJSON();
  const langOut = {
    ...j,
    colorHex: j.color_hex,
    darkHex: j.dark_hex,
    scriptPreview: j.script_preview || '',
    speakers: j.speakers || '',
    region: j.region || '',
    helloTarget: j.hello_target,
    helloMeaning: j.hello_meaning,
    icon: j.icon,
    id: j.code,
  };
  delete langOut.color_hex; delete langOut.dark_hex; delete langOut.hello_target; delete langOut.hello_meaning;
  delete langOut.is_active; delete langOut.sort_order; delete langOut.created_at; delete langOut.script_preview; delete langOut.code;

  const unitsOut = unitsList.map(u => {
    const r = u.toJSON();
    return {
      ...r,
      colorHex: r.color_hex,
      darkHex: r.dark_hex,
      teachContent: r.teach_content || [],
    };
  });
  unitsOut.forEach(u => {
    delete u.color_hex; delete u.dark_hex; delete u.language_id;
    delete u.sort_order; delete u.created_at; delete u.teach_content;
  });

  const lessonsOut = lessonsList.map(l => {
    const r = l.toJSON();
    return {
      ...r,
      isBoss: r.is_boss,
      xpReward: r.xp_reward,
      teachContent: r.teach_content || [],
      resources: r.resources || [],
      unitId: r.unit_id,
    };
  });
  lessonsOut.forEach(l => {
    delete l.is_boss; delete l.xp_reward; delete l.teach_content;
    // keep camelCase `resources` for the mobile app
    delete l.unit_id; delete l.sort_order; delete l.created_at;
  });

  const questionsOut = questionsList.map(q => {
    const r = q.toJSON();
    return {
      ...r,
      content: r.content || {},
      subPrompt: r.sub_prompt || '',
      answerIndex: r.answer_index,
      matchLeft: r.match_left,
      matchRight: r.match_right,
      audioUrl: r.audio_url || '',
      lessonId: r.lesson_id,
      hint: r.hint || '',
    };
  });
  questionsOut.forEach(q => { delete q.sub_prompt; delete q.lesson_id; delete q.sort_order; delete q.created_at; });

  res.json({
    language: langOut,
    units: unitsOut,
    lessons: lessonsOut,
    questions: questionsOut,
    phrases: phrasesList.map(p => p.toJSON()),
  });
}

export async function languagePhrases(req, res) {
  const lang = await Language.findOne({ where: { code: req.params.code, is_active: true } });
  if (!lang) return res.status(404).json({ error: 'language not found' });
  const list = await Phrase.findAll({
    where: { language_id: lang.id },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  res.json(list);
}

export async function appBaseLanguages(_req, res) {
  const rows = await BaseLanguage.findAll({
    where: { is_active: true },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  res.json(rows.map(l => {
    const j = l.toJSON();
    return { id: j.code, name: j.name, nativeName: j.native_name };
  }));
}