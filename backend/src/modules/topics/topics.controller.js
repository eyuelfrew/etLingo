import { TopicCategory, TopicWord } from './topics.models.js';
import { Language } from '../content/content.models.js';
import { asyncHandler, badRequest, notFound } from '../../core/http.js';

function pick(obj, fields) {
  const out = {};
  for (const f of fields) if (obj[f] !== undefined) out[f] = obj[f];
  return out;
}

const catFields = [
  'language_id', 'slug', 'title', 'native_title', 'emoji',
  'color_hex', 'description', 'is_active', 'sort_order',
];
const wordFields = [
  'category_id', 'target', 'translit', 'meaning', 'meanings',
  'audio_url', 'image_url', 'notes', 'sort_order',
];

function catOut(r) {
  const x = r.toJSON ? r.toJSON() : r;
  return {
    id: x.id,
    languageId: x.language_id,
    slug: x.slug,
    title: x.title,
    nativeTitle: x.native_title || '',
    emoji: x.emoji || '',
    colorHex: x.color_hex || '#078930',
    description: x.description || '',
    isActive: !!x.is_active,
    sortOrder: x.sort_order ?? 0,
  };
}

function wordOut(r) {
  const x = r.toJSON ? r.toJSON() : r;
  return {
    id: x.id,
    categoryId: x.category_id,
    target: x.target,
    translit: x.translit || '',
    meaning: x.meaning || '',
    meanings: x.meanings || {},
    audioUrl: x.audio_url || '',
    imageUrl: x.image_url || '',
    notes: x.notes || '',
    sortOrder: x.sort_order ?? 0,
  };
}

function meaningFor(word, base) {
  const m = word.meanings || {};
  if (m && typeof m === 'object' && m[base]) return String(m[base]);
  return word.meaning || '';
}

// ── Admin categories ─────────────────────────────────────────────────────────

export const listCategories = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.language_id) where.language_id = Number(req.query.language_id);
  const rows = await TopicCategory.findAll({
    where,
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  res.json(rows.map(catOut));
});

export const createCategory = asyncHandler(async (req, res) => {
  const data = pick(req.body, catFields);
  if (!data.language_id) throw badRequest('language_id is required');
  if (!data.slug) throw badRequest('slug is required');
  if (!data.title) throw badRequest('title is required');
  data.slug = String(data.slug).trim().toLowerCase().replace(/\s+/g, '-');
  const exists = await TopicCategory.findOne({
    where: { language_id: data.language_id, slug: data.slug },
  });
  if (exists) throw badRequest(`Category "${data.slug}" already exists`);
  const row = await TopicCategory.create(data);
  res.status(201).json(catOut(row));
});

export const updateCategory = asyncHandler(async (req, res) => {
  const row = await TopicCategory.findByPk(req.params.id);
  if (!row) throw notFound('Category not found');
  await row.update(pick(req.body, catFields));
  res.json(catOut(row));
});

export const deleteCategory = asyncHandler(async (req, res) => {
  const row = await TopicCategory.findByPk(req.params.id);
  if (!row) throw notFound('Category not found');
  await TopicWord.destroy({ where: { category_id: row.id } });
  await row.destroy();
  res.status(204).end();
});

// ── Admin words ──────────────────────────────────────────────────────────────

export const listWords = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.category_id) where.category_id = Number(req.query.category_id);
  const rows = await TopicWord.findAll({
    where,
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  res.json(rows.map(wordOut));
});

export const createWord = asyncHandler(async (req, res) => {
  const data = pick(req.body, wordFields);
  if (!data.category_id) throw badRequest('category_id is required');
  if (!data.target) throw badRequest('target is required');
  const row = await TopicWord.create(data);
  res.status(201).json(wordOut(row));
});

export const updateWord = asyncHandler(async (req, res) => {
  const row = await TopicWord.findByPk(req.params.id);
  if (!row) throw notFound('Word not found');
  await row.update(pick(req.body, wordFields));
  res.json(wordOut(row));
});

export const deleteWord = asyncHandler(async (req, res) => {
  const row = await TopicWord.findByPk(req.params.id);
  if (!row) throw notFound('Word not found');
  await row.destroy();
  res.status(204).end();
});

/** POST /admin/topic-words/bulk — replace words for a category. */
export const bulkWords = asyncHandler(async (req, res) => {
  const categoryId = Number(req.params.id);
  const cat = await TopicCategory.findByPk(categoryId);
  if (!cat) throw notFound('Category not found');
  const items = Array.isArray(req.body?.words) ? req.body.words : [];
  if (req.body?.replace) {
    await TopicWord.destroy({ where: { category_id: categoryId } });
  }
  let n = 0;
  for (let i = 0; i < items.length; i++) {
    const item = items[i] || {};
    const target = String(item.target || '').trim();
    if (!target) continue;
    await TopicWord.create({
      category_id: categoryId,
      target,
      translit: String(item.translit || '').trim(),
      meaning: String(item.meaning || '').trim(),
      meanings: item.meanings || null,
      audio_url: String(item.audioUrl || item.audio_url || '').trim(),
      image_url: String(item.imageUrl || item.image_url || '').trim(),
      notes: String(item.notes || '').trim(),
      sort_order: Number(item.sortOrder ?? item.sort_order ?? i) || 0,
    });
    n += 1;
  }
  res.json({ imported: n });
});

// ── App ──────────────────────────────────────────────────────────────────────

/** GET /app/topics/:code — categories + words for a course language. */
export const appTopics = asyncHandler(async (req, res) => {
  const code = (req.params.code || '').toString();
  const base = (req.query.base || 'en').toString();
  const lang = await Language.findOne({ where: { code, is_active: true } });
  if (!lang) throw notFound('language not found');

  const cats = await TopicCategory.findAll({
    where: { language_id: lang.id, is_active: true },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  const ids = cats.map((c) => c.id);
  const words = ids.length
    ? await TopicWord.findAll({
        where: { category_id: ids },
        order: [['sort_order', 'ASC'], ['id', 'ASC']],
      })
    : [];

  const byCat = new Map();
  for (const w of words) {
    const cid = w.category_id;
    if (!byCat.has(cid)) byCat.set(cid, []);
    const wo = wordOut(w);
    wo.meaningLocal = meaningFor(wo, base);
    byCat.get(cid).push(wo);
  }

  res.json({
    language: {
      code: lang.code,
      name: lang.name,
      nativeName: lang.native_name,
    },
    categories: cats.map((c) => ({
      ...catOut(c),
      wordCount: (byCat.get(c.id) || []).length,
      words: byCat.get(c.id) || [],
    })),
  });
});

/** GET /app/topics/:code/:slug — one pack. */
export const appTopicPack = asyncHandler(async (req, res) => {
  const code = (req.params.code || '').toString();
  const slug = (req.params.slug || '').toString().toLowerCase();
  const base = (req.query.base || 'en').toString();
  const lang = await Language.findOne({ where: { code, is_active: true } });
  if (!lang) throw notFound('language not found');
  const cat = await TopicCategory.findOne({
    where: { language_id: lang.id, slug, is_active: true },
  });
  if (!cat) throw notFound('topic not found');
  const words = await TopicWord.findAll({
    where: { category_id: cat.id },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  const list = words.map((w) => {
    const wo = wordOut(w);
    wo.meaningLocal = meaningFor(wo, base);
    return wo;
  });
  res.json({ ...catOut(cat), words: list });
});
