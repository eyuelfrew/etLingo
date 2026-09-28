import { CommunityStory, ExchangeSignup } from './community.models.js';
import { asyncHandler, badRequest, notFound, unauthorized } from '../../core/http.js';

function clean(s, max) {
  const t = String(s || '').trim();
  return t.slice(0, max);
}

async function displayName(userId) {
  const { AppUser } = await import('../users/users.models.js');
  const u = await AppUser.findByPk(userId);
  return u?.display_name || u?.email || `Learner ${userId}`;
}

function storyOut(row, authorName) {
  const r = row.toJSON ? row.toJSON() : row;
  return {
    id: r.id,
    userId: r.user_id,
    author: authorName || `Learner ${r.user_id}`,
    languageCode: r.language_code || 'am',
    title: r.title,
    body: r.body || '',
    audioUrl: r.audio_url || '',
    status: r.status,
    createdAt: r.created_at,
  };
}

// ── Community stories ────────────────────────────────────────────────────────

export const submitStory = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const userId = Number(req.auth.sub);
  const title = clean(req.body?.title, 160);
  const body = clean(req.body?.body, 2000);
  if (!title) throw badRequest('title is required');
  if (!body) throw badRequest('body is required');
  const row = await CommunityStory.create({
    user_id: userId,
    language_code: clean(req.body?.languageCode, 8) || 'am',
    title,
    body,
    audio_url: clean(req.body?.audioUrl, 255),
    status: 'pending',
  });
  res.status(201).json({
    ...storyOut(row, await displayName(userId)),
    message: 'Thanks — a moderator will review your story soon.',
  });
});

export const listApprovedStories = asyncHandler(async (req, res) => {
  const where = { status: 'approved' };
  if (req.query.language_code) where.language_code = String(req.query.language_code);
  const rows = await CommunityStory.findAll({
    where,
    order: [['created_at', 'DESC'], ['id', 'DESC']],
    limit: 50,
  });
  const names = new Map();
  for (const r of rows) {
    if (!names.has(r.user_id)) names.set(r.user_id, await displayName(r.user_id));
  }
  res.json(rows.map((r) => storyOut(r, names.get(r.user_id))));
});

export const myStories = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const rows = await CommunityStory.findAll({
    where: { user_id: Number(req.auth.sub) },
    order: [['created_at', 'DESC']],
  });
  res.json(rows.map((r) => storyOut(r, 'You')));
});

export const adminListStories = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.status) where.status = String(req.query.status);
  const rows = await CommunityStory.findAll({
    where,
    order: [['created_at', 'DESC'], ['id', 'DESC']],
    limit: 200,
  });
  const names = new Map();
  for (const r of rows) {
    if (!names.has(r.user_id)) names.set(r.user_id, await displayName(r.user_id));
  }
  res.json(rows.map((r) => storyOut(r, names.get(r.user_id))));
});

export const adminModerateStory = asyncHandler(async (req, res) => {
  const row = await CommunityStory.findByPk(req.params.id);
  if (!row) throw notFound('Story not found');
  const status = String(req.body?.status || '');
  if (!['approved', 'rejected', 'pending'].includes(status)) {
    throw badRequest('status must be approved, rejected, or pending');
  }
  await row.update({
    status,
    moderator_note: clean(req.body?.moderatorNote, 255),
  });
  res.json(storyOut(row));
});

// ── Language exchange ────────────────────────────────────────────────────────

export const exchangeSignup = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const userId = Number(req.auth.sub);
  const speaks = clean(req.body?.speaks, 8);
  const learning = clean(req.body?.learning, 8);
  if (!speaks || !learning) throw badRequest('speaks and learning are required');
  if (speaks === learning) throw badRequest('speaks and learning must differ');
  const [row, created] = await ExchangeSignup.findOrCreate({
    where: { user_id: userId },
    defaults: {
      user_id: userId,
      speaks,
      learning,
      note: clean(req.body?.note, 300),
      status: 'waiting',
    },
  });
  if (!created) {
    await row.update({
      speaks,
      learning,
      note: clean(req.body?.note, 300) || row.note,
    });
  }
  res.status(created ? 201 : 200).json({
    id: row.id,
    speaks: row.speaks,
    learning: row.learning,
    note: row.note,
    status: row.status,
    message: 'You are on the exchange list. We will notify you when we match partners.',
  });
});

export const myExchange = asyncHandler(async (req, res) => {
  if (req.auth?.sub == null) throw unauthorized('Sign in required');
  const row = await ExchangeSignup.findOne({
    where: { user_id: Number(req.auth.sub) },
  });
  res.json(row ? {
    id: row.id,
    speaks: row.speaks,
    learning: row.learning,
    note: row.note,
    status: row.status,
    createdAt: row.created_at,
  } : null);
});

export const adminListExchange = asyncHandler(async (req, res) => {
  const rows = await ExchangeSignup.findAll({
    order: [['created_at', 'ASC']],
    limit: 500,
  });
  const names = new Map();
  for (const r of rows) {
    if (!names.has(r.user_id)) names.set(r.user_id, await displayName(r.user_id));
  }
  res.json(rows.map((r) => ({
    id: r.id,
    userId: r.user_id,
    author: names.get(r.user_id) || `Learner ${r.user_id}`,
    speaks: r.speaks,
    learning: r.learning,
    note: r.note || '',
    status: r.status,
    createdAt: r.created_at,
  })));
});

export const adminUpdateExchange = asyncHandler(async (req, res) => {
  const row = await ExchangeSignup.findByPk(req.params.id);
  if (!row) throw notFound('Signup not found');
  const status = String(req.body?.status || '');
  if (!['waiting', 'matched', 'closed'].includes(status)) {
    throw badRequest('status must be waiting, matched, or closed');
  }
  await row.update({ status });
  res.json({ id: row.id, status: row.status });
});
