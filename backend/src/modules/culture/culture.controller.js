import { CultureUnit, CultureCard, CultureProgress } from './culture.models.js';
import { Language } from '../content/content.models.js';
import { AppUser } from '../users/users.models.js';
import { Op } from 'sequelize';
import { asyncHandler, badRequest, notFound, unauthorized } from '../../core/http.js';
import { activeHoliday, holidayXpMultiplier, upcomingHoliday } from './holidays.js';

const cardFields = [
  'culture_unit_id', 'kind', 'title', 'body', 'translit',
  'audio_url', 'pdf_url', 'sort_order', 'xp_reward',
];
const cardJson = ['content', 'resources', 'vocab', 'meta'];
const unitFields = [
  'language_id', 'title', 'subtitle', 'theme', 'color_hex', 'dark_hex',
  'icon', 'sort_order', 'is_active',
];

function pick(obj, fields) {
  const out = {};
  for (const f of fields) if (obj[f] !== undefined) out[f] = obj[f];
  return out;
}

function cardOut(row) {
  const r = row.toJSON ? row.toJSON() : row;
  return {
    id: r.id,
    cultureUnitId: r.culture_unit_id,
    kind: r.kind,
    title: r.title,
    body: r.body || '',
    content: r.content || {},
    translit: r.translit || '',
    audioUrl: r.audio_url || '',
    pdfUrl: r.pdf_url || '',
    resources: r.resources || [],
    vocab: r.vocab || [],
    meta: r.meta || {},
    xpReward: r.xp_reward ?? 5,
    sortOrder: r.sort_order ?? 0,
    completedAt: r.completed_at || null,
  };
}

function unitOut(row) {
  const r = row.toJSON ? row.toJSON() : row;
  return {
    id: r.id,
    languageId: r.language_id,
    title: r.title,
    subtitle: r.subtitle || '',
    theme: r.theme || 'fact',
    colorHex: r.color_hex,
    darkHex: r.dark_hex,
    icon: r.icon,
    isActive: !!r.is_active,
  };
}

function textFor(card, baseLang) {
  const c = card.content || {};
  const node = c[baseLang];
  if (node && typeof node === 'object') {
    return {
      title: node.title || card.title,
      body: node.body || card.body,
    };
  }
  return { title: card.title, body: card.body };
}

// ── Admin CRUD ───────────────────────────────────────────────────────────────

export const adminListUnits = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.language_id) where.language_id = Number(req.query.language_id);
  const rows = await CultureUnit.findAll({
    where,
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  res.json(rows);
});

export const adminCreateUnit = asyncHandler(async (req, res) => {
  const data = pick(req.body, unitFields);
  if (!data.title) throw badRequest('title is required');
  if (!data.language_id) throw badRequest('language_id is required');
  const row = await CultureUnit.create(data);
  res.status(201).json(row);
});

export const adminUpdateUnit = asyncHandler(async (req, res) => {
  const row = await CultureUnit.findByPk(req.params.id);
  if (!row) throw notFound('Culture unit not found');
  await row.update(pick(req.body, unitFields));
  res.json(row);
});

export const adminDeleteUnit = asyncHandler(async (req, res) => {
  const row = await CultureUnit.findByPk(req.params.id);
  if (!row) throw notFound('Culture unit not found');
  await CultureCard.destroy({ where: { culture_unit_id: row.id } });
  await row.destroy();
  res.status(204).end();
});

export const adminListCards = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.culture_unit_id) {
    where.culture_unit_id = Number(req.query.culture_unit_id);
  }
  const rows = await CultureCard.findAll({
    where,
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  res.json(rows);
});

export const adminCreateCard = asyncHandler(async (req, res) => {
  const data = { ...pick(req.body, cardFields), ...pick(req.body, cardJson) };
  if (!data.title) throw badRequest('title is required');
  if (!data.culture_unit_id) throw badRequest('culture_unit_id is required');
  const row = await CultureCard.create(data);
  res.status(201).json(cardOut(row));
});

export const adminUpdateCard = asyncHandler(async (req, res) => {
  const row = await CultureCard.findByPk(req.params.id);
  if (!row) throw notFound('Culture card not found');
  await row.update({ ...pick(req.body, cardFields), ...pick(req.body, cardJson) });
  res.json(cardOut(row));
});

export const adminDeleteCard = asyncHandler(async (req, res) => {
  const row = await CultureCard.findByPk(req.params.id);
  if (!row) throw notFound('Culture card not found');
  await row.destroy();
  res.status(204).end();
});

// ── Public app bootstrap ─────────────────────────────────────────────────────

export const cultureBootstrap = asyncHandler(async (req, res) => {
  const code = (req.params.code || '').toString();
  const lang = await Language.findOne({ where: { code, is_active: true } });
  if (!lang) throw notFound('language not found');

  const units = await CultureUnit.findAll({
    where: { language_id: lang.id, is_active: true },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  const unitIds = units.map((u) => u.id);
  const cards = unitIds.length
    ? await CultureCard.findAll({
        where: { culture_unit_id: unitIds },
        order: [['sort_order', 'ASC'], ['id', 'ASC']],
      })
    : [];

  const viewerId = req.auth?.sub != null ? Number(req.auth.sub) : null;
  let doneIds = [];
  if (viewerId) {
    const rows = await CultureProgress.findAll({
      where: { user_id: viewerId, culture_card_id: cards.map((c) => c.id) },
      attributes: ['culture_card_id'],
    }).catch(() => []);
    doneIds = (rows || []).map((r) => String(r.culture_card_id));
  }

  res.json({
    language: {
      id: lang.code,
      dbId: lang.id,
      name: lang.name,
      nativeName: lang.native_name,
      colorHex: lang.color_hex,
      darkHex: lang.dark_hex,
    },
    units: units.map(unitOut),
    cards: cards.map(cardOut),
    completedCardIds: doneIds,
  });
});

/** Optional mini endpoint: today’s proverb from any proverb card. */
export const proverbOfDay = asyncHandler(async (req, res) => {
  const code = (req.params.code || req.query.lang || '').toString();
  const base = (req.query.base || 'en').toString();
  const lang = await Language.findOne({ where: { code, is_active: true } });
  if (!lang) throw notFound('language not found');

  const units = await CultureUnit.findAll({
    where: { language_id: lang.id, is_active: true },
    attributes: ['id'],
  });
  const unitIds = units.map((u) => u.id);
  const proverbs = unitIds.length
    ? await CultureCard.findAll({
        where: { culture_unit_id: unitIds, kind: 'proverb' },
        order: [['sort_order', 'ASC'], ['id', 'ASC']],
      })
    : [];
  if (!proverbs.length) return res.json(null);

  const day = Math.floor(Date.now() / 86400000);
  const card = proverbs[day % proverbs.length];
  const t = textFor(card, base);
  res.json({
    ...cardOut(card),
    title: t.title,
    body: t.body,
  });
});

// ── Progress + XP ───────────────────────────────────────────────────────────

export const completeCard = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const userId = Number(req.auth.sub);
  const cardId = Number(req.params.id);
  if (!Number.isInteger(cardId) || cardId <= 0) throw badRequest('Invalid card id');

  const card = await CultureCard.findByPk(cardId);
  if (!card) throw notFound('Culture card not found');

  const [, created] = await CultureProgress.findOrCreate({
    where: { user_id: userId, culture_card_id: cardId },
    defaults: { user_id: userId, culture_card_id: cardId, completed_at: new Date() },
  });

  const baseXp = Number(card.xp_reward) || 5;
  const multiplier = holidayXpMultiplier();
  const earned = created ? baseXp * multiplier : 0;
  if (earned) {
    const user = await AppUser.findByPk(userId);
    if (user) {
      await user.update({ xp: (Number(user.xp) || 0) + earned });
    }
  }

  const done = await CultureProgress.count({ where: { user_id: userId } });
  const holiday = activeHoliday();
  res.json({
    cardId,
    earned,
    baseXp,
    multiplier,
    holiday: holiday ? { key: holiday.key, name: holiday.name, nameAm: holiday.nameAm } : null,
    alreadyDone: !created,
    completedCards: done,
  });
});

/** Calendar + holiday context for the app chip / challenge banner. */
export const cultureCalendar = asyncHandler(async (req, res) => {
  const now = new Date();
  const holiday = activeHoliday(now);
  const upcoming = upcomingHoliday(45, now);
  res.json({
    gregorian: now.toISOString().slice(0, 10),
    holiday,
    upcoming,
    xpMultiplier: holiday ? holiday.xpMultiplier : 1,
  });
});

export const myCultureProgress = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const rows = await CultureProgress.findAll({
    where: { user_id: Number(req.auth.sub) },
    attributes: ['culture_card_id'],
  });
  res.json({ completedCardIds: rows.map((r) => String(r.culture_card_id)) });
});
