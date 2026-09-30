import { Op } from 'sequelize';
import {
  UnitLike,
  UnitComment,
  LanguageLike,
  LanguageComment,
} from './engagement.models.js';
import {
  CultureUnitLike,
  CultureUnitComment,
} from './culture_engagement.js';
import { asyncHandler, badRequest, unauthorized } from '../../core/http.js';
import { sanitizeText } from '../../core/security.js';

function cleanBody(body) {
  const s = sanitizeText(body, 500);
  if (!s) throw badRequest('Comment cannot be empty');
  return s;
}

async function namesForUserIds(ids) {
  if (!ids.length) return new Map();
  const { AppUser } = await import('../users/users.models.js');
  const rows = await AppUser.findAll({
    where: { id: { [Op.in]: [...ids] } },
    attributes: ['id', 'display_name', 'email'],
  });
  const map = new Map();
  for (const u of rows) {
    map.set(u.id, u.display_name || u.email || `Learner ${u.id}`);
  }
  return map;
}

function serializeComments(rows, nameMap, viewerId) {
  return rows.map((c) => ({
    id: c.id,
    userId: c.user_id,
    author: nameMap.get(c.user_id) || `Learner ${c.user_id}`,
    body: c.body,
    createdAt: c.created_at,
    mine: viewerId != null && Number(c.user_id) === Number(viewerId),
  }));
}

/** GET /app/engagement/units/:id  (public counts; likedByMe if signed in) */
export const getUnitEngagement = asyncHandler(async (req, res) => {
  const unitId = Number(req.params.id);
  if (!Number.isInteger(unitId) || unitId <= 0) throw badRequest('Invalid unit id');
  const viewerId = req.auth?.sub != null ? Number(req.auth.sub) : null;

  const [likes, comments] = await Promise.all([
    UnitLike.count({ where: { unit_id: unitId } }),
    UnitComment.findAll({
      where: { unit_id: unitId },
      order: [['created_at', 'DESC'], ['id', 'DESC']],
      limit: 50,
    }),
  ]);
  const likedByMe = viewerId == null
    ? false
    : (await UnitLike.count({ where: { unit_id: unitId, user_id: viewerId } })) > 0;
  const names = await namesForUserIds(comments.map((c) => c.user_id));

  res.json({
    target: 'unit',
    id: unitId,
    likes,
    likedByMe,
    commentCount: comments.length,
    comments: serializeComments(comments, names, viewerId),
  });
});

export const getLanguageEngagement = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) throw badRequest('Invalid language id');
  const viewerId = req.auth?.sub != null ? Number(req.auth.sub) : null;

  const [likes, comments] = await Promise.all([
    LanguageLike.count({ where: { language_id: id } }),
    LanguageComment.findAll({
      where: { language_id: id },
      order: [['created_at', 'DESC'], ['id', 'DESC']],
      limit: 50,
    }),
  ]);
  const likedByMe = viewerId == null
    ? false
    : (await LanguageLike.count({ where: { language_id: id, user_id: viewerId } })) > 0;
  const names = await namesForUserIds(comments.map((c) => c.user_id));

  res.json({
    target: 'language',
    id,
    likes,
    likedByMe,
    commentCount: comments.length,
    comments: serializeComments(comments, names, viewerId),
  });
});

/**
 * Like once — sticky. Tapping again does NOT unlike.
 * Each user gets at most one like row per unit/language (unique index).
 */
async function ensureLike(Model, field, id, userId) {
  const [, created] = await Model.findOrCreate({
    where: { [field]: id, user_id: userId },
    defaults: { [field]: id, user_id: userId },
  });
  const likes = await Model.count({ where: { [field]: id } });
  return { liked: true, alreadyLiked: !created, likes };
}

export const likeUnit = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const unitId = Number(req.params.id);
  if (!Number.isInteger(unitId) || unitId <= 0) throw badRequest('Invalid unit id');
  const result = await ensureLike(UnitLike, 'unit_id', unitId, Number(req.auth.sub));
  console.log(`[engagement] user #${req.auth.sub} like unit ${unitId} → likes=${result.likes}`);
  res.status(200).type('application/json').json({
    target: 'unit',
    id: unitId,
    liked: true,
    alreadyLiked: result.alreadyLiked,
    likes: result.likes,
  });
});

export const likeLanguage = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) throw badRequest('Invalid language id');
  const result = await ensureLike(LanguageLike, 'language_id', id, Number(req.auth.sub));
  console.log(`[engagement] user #${req.auth.sub} like language ${id} → likes=${result.likes}`);
  res.status(200).type('application/json').json({
    target: 'language',
    id,
    liked: true,
    alreadyLiked: result.alreadyLiked,
    likes: result.likes,
  });
});

export const commentOnUnit = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized();
  const unitId = Number(req.params.id);
  if (!Number.isInteger(unitId) || unitId <= 0) throw badRequest('Invalid unit id');
  const userId = Number(req.auth.sub);
  const body = cleanBody(req.body?.body);
  const row = await UnitComment.create({ unit_id: unitId, user_id: userId, body });
  const { AppUser } = await import('../users/users.models.js');
  const me = await AppUser.findByPk(userId);
  res.status(201).json({
    target: 'unit',
    id: unitId,
    comment: {
      id: row.id,
      userId,
      author: me?.display_name || me?.email || `Learner ${userId}`,
      body: row.body,
      createdAt: row.created_at,
      mine: true,
    },
  });
});

export const commentOnLanguage = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized();
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) throw badRequest('Invalid language id');
  const userId = Number(req.auth.sub);
  const body = cleanBody(req.body?.body);
  const row = await LanguageComment.create({ language_id: id, user_id: userId, body });
  const { AppUser } = await import('../users/users.models.js');
  const me = await AppUser.findByPk(userId);
  res.status(201).json({
    target: 'language',
    id,
    comment: {
      id: row.id,
      userId,
      author: me?.display_name || me?.email || `Learner ${userId}`,
      body: row.body,
      createdAt: row.created_at,
      mine: true,
    },
  });
});

// ── Culture unit engagement ──────────────────────────────────────────────────

export const getCultureUnitEngagement = asyncHandler(async (req, res) => {
  const unitId = Number(req.params.id);
  if (!Number.isInteger(unitId) || unitId <= 0) throw badRequest('Invalid culture unit id');
  const viewerId = req.auth?.sub != null ? Number(req.auth.sub) : null;

  const [likes, comments] = await Promise.all([
    CultureUnitLike.count({ where: { culture_unit_id: unitId } }),
    CultureUnitComment.findAll({
      where: { culture_unit_id: unitId },
      order: [['created_at', 'DESC'], ['id', 'DESC']],
      limit: 50,
    }),
  ]);
  const likedByMe = viewerId == null
    ? false
    : (await CultureUnitLike.count({
        where: { culture_unit_id: unitId, user_id: viewerId },
      })) > 0;
  const names = await namesForUserIds(comments.map((c) => c.user_id));

  res.json({
    target: 'cultureUnit',
    id: unitId,
    likes,
    likedByMe,
    commentCount: comments.length,
    comments: serializeComments(comments, names, viewerId),
  });
});

export const likeCultureUnit = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const unitId = Number(req.params.id);
  if (!Number.isInteger(unitId) || unitId <= 0) throw badRequest('Invalid culture unit id');
  const result = await ensureLike(
    CultureUnitLike,
    'culture_unit_id',
    unitId,
    Number(req.auth.sub),
  );
  console.log(`[engagement] user #${req.auth.sub} like culture unit ${unitId} → likes=${result.likes}`);
  res.status(200).type('application/json').json({
    target: 'cultureUnit',
    id: unitId,
    liked: true,
    alreadyLiked: result.alreadyLiked,
    likes: result.likes,
  });
});

export const commentOnCultureUnit = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized();
  const unitId = Number(req.params.id);
  if (!Number.isInteger(unitId) || unitId <= 0) throw badRequest('Invalid culture unit id');
  const userId = Number(req.auth.sub);
  const body = cleanBody(req.body?.body);
  const row = await CultureUnitComment.create({
    culture_unit_id: unitId,
    user_id: userId,
    body,
  });
  const { AppUser } = await import('../users/users.models.js');
  const me = await AppUser.findByPk(userId);
  res.status(201).json({
    target: 'cultureUnit',
    id: unitId,
    comment: {
      id: row.id,
      userId,
      author: me?.display_name || me?.email || `Learner ${userId}`,
      body: row.body,
      createdAt: row.created_at,
      mine: true,
    },
  });
});

export const adminCultureUnitEngagement = asyncHandler(async (req, res) => {
  const unitId = Number(req.params.id);
  const [likes, comments] = await Promise.all([
    CultureUnitLike.count({ where: { culture_unit_id: unitId } }),
    CultureUnitComment.findAll({
      where: { culture_unit_id: unitId },
      order: [['created_at', 'DESC']],
      limit: 100,
    }),
  ]);
  const names = await namesForUserIds(comments.map((c) => c.user_id));
  res.json({
    likes,
    commentCount: comments.length,
    comments: serializeComments(comments, names, null),
  });
});

/** Admin: engagement summary for a unit or language */
export const adminUnitEngagement = asyncHandler(async (req, res) => {
  const unitId = Number(req.params.id);
  const [likes, comments] = await Promise.all([
    UnitLike.count({ where: { unit_id: unitId } }),
    UnitComment.findAll({
      where: { unit_id: unitId },
      order: [['created_at', 'DESC']],
      limit: 100,
    }),
  ]);
  const names = await namesForUserIds(comments.map((c) => c.user_id));
  res.json({
    likes,
    commentCount: comments.length,
    comments: serializeComments(comments, names, null),
  });
});

export const adminLanguageEngagement = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const [likes, comments] = await Promise.all([
    LanguageLike.count({ where: { language_id: id } }),
    LanguageComment.findAll({
      where: { language_id: id },
      order: [['created_at', 'DESC']],
      limit: 100,
    }),
  ]);
  const names = await namesForUserIds(comments.map((c) => c.user_id));
  res.json({
    likes,
    commentCount: comments.length,
    comments: serializeComments(comments, names, null),
  });
});
