import { Ad } from './ads.models.js';
import { Op } from 'sequelize';
import { asyncHandler, badRequest, notFound } from '../../core/http.js';

function pick(obj, fields) {
  const out = {};
  for (const f of fields) if (obj[f] !== undefined) out[f] = obj[f];
  return out;
}

const fields = [
  'title', 'body', 'image_url', 'cta_label', 'position', 'action_type',
  'action_value', 'language_code', 'priority', 'is_active', 'starts_at', 'ends_at',
];

export const POSITIONS = [
  { key: 'home_top', label: 'Learn home · top' },
  { key: 'home_mid', label: 'Learn home · between units' },
  { key: 'culture_top', label: 'Culture · top' },
  { key: 'after_topics', label: 'After topic packs' },
  { key: 'profile', label: 'You / Profile' },
];

function adOut(r) {
  const x = r.toJSON ? r.toJSON() : r;
  return {
    id: x.id,
    title: x.title,
    body: x.body || '',
    imageUrl: x.image_url || '',
    ctaLabel: x.cta_label || 'Learn more',
    position: x.position,
    actionType: x.action_type || 'url',
    actionValue: x.action_value || '',
    languageCode: x.language_code || '',
    priority: x.priority ?? 0,
    isActive: !!x.is_active,
    startsAt: x.starts_at || null,
    endsAt: x.ends_at || null,
    impressions: x.impressions ?? 0,
    clicks: x.clicks ?? 0,
  };
}

function liveWhere(extra = {}) {
  const now = new Date();
  return {
    ...extra,
    is_active: true,
    [Op.and]: [
      { [Op.or]: [{ starts_at: null }, { starts_at: { [Op.lte]: now } }] },
      { [Op.or]: [{ ends_at: null }, { ends_at: { [Op.gte]: now } }] },
    ],
  };
}

// ── Admin ────────────────────────────────────────────────────────────────────

export const adminListAds = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.position) where.position = String(req.query.position);
  const rows = await Ad.findAll({
    where,
    order: [['priority', 'DESC'], ['id', 'DESC']],
    limit: 200,
  });
  res.json(rows.map(adOut));
});

export const adminCreateAd = asyncHandler(async (req, res) => {
  const data = pick(req.body, fields);
  if (!data.title) throw badRequest('title is required');
  if (!data.position) throw badRequest('position is required');
  const row = await Ad.create(data);
  res.status(201).json(adOut(row));
});

export const adminUpdateAd = asyncHandler(async (req, res) => {
  const row = await Ad.findByPk(req.params.id);
  if (!row) throw notFound('Ad not found');
  await row.update(pick(req.body, fields));
  res.json(adOut(row));
});

export const adminDeleteAd = asyncHandler(async (req, res) => {
  const row = await Ad.findByPk(req.params.id);
  if (!row) throw notFound('Ad not found');
  await row.destroy();
  res.status(204).end();
});

// ── App ──────────────────────────────────────────────────────────────────────

/**
 * GET /app/ads?position=home_top&lang=am
 * Returns one best live ad (or null).
 */
export const appAd = asyncHandler(async (req, res) => {
  const position = (req.query.position || 'home_top').toString();
  const lang = (req.query.lang || '').toString();
  const where = liveWhere({ position });
  if (lang) {
    where[Op.or] = [
      { language_code: '' },
      { language_code: null },
      { language_code: lang },
    ];
  }
  const rows = await Ad.findAll({
    where,
    order: [['priority', 'DESC'], ['id', 'DESC']],
    limit: 1,
  });
  const row = rows[0];
  if (!row) return res.json(null);
  // Count impression (fire-and-forget)
  Ad.increment('impressions', { where: { id: row.id } }).catch(() => {});
  res.json(adOut(row));
});

/** GET /app/ads — all live ads for a language (app can cache). */
export const appAds = asyncHandler(async (req, res) => {
  const lang = (req.query.lang || '').toString();
  const where = liveWhere();
  if (lang) {
    where[Op.or] = [
      { language_code: '' },
      { language_code: null },
      { language_code: lang },
    ];
  }
  const rows = await Ad.findAll({
    where,
    order: [['priority', 'DESC'], ['id', 'DESC']],
    limit: 50,
  });
  res.json(rows.map(adOut));
});

/** POST /app/ads/:id/click — tap tracking. */
export const adClick = asyncHandler(async (req, res) => {
  const row = await Ad.findByPk(req.params.id);
  if (!row) throw notFound('Ad not found');
  await Ad.increment('clicks', { where: { id: row.id } });
  res.json({
    id: row.id,
    actionType: row.action_type,
    actionValue: row.action_value,
    clicks: (row.clicks || 0) + 1,
    impressions: row.impressions || 0,
  });
});

export const adminPositions = asyncHandler(async (_req, res) => {
  res.json(POSITIONS);
});
