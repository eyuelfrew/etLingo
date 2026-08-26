import bcrypt from 'bcryptjs';
import { Op } from 'sequelize';
import { AppUser, LessonProgress } from './users.models.js';
import { asyncHandler, badRequest, notFound, unauthorized } from '../../core/http.js';

function toUser(u) {
  return {
    id: u.id,
    email: u.email,
    displayName: u.display_name,
    provider: u.provider,
    status: u.status,
    xp: u.xp,
    hearts: u.hearts,
    streak: u.streak,
    lastActiveDate: u.last_active_date,
    createdAt: u.created_at,
  };
}

async function withStats(user) {
  const count = await LessonProgress.count({ where: { app_user_id: user.id } });
  return { ...toUser(user), lessonsDone: count };
}

// ── App user self-service ─────────────────────────────────────────────────────

// Register/update this device's FCM push token so the notifications module can
// deliver device notifications to this learner. Bound to the caller's user id.
export const registerFcmToken = asyncHandler(async (req, res) => {
  const user = await AppUser.findByPk(req.auth.sub);
  if (!user) throw unauthorized('User not found');

  const { fcmToken } = req.body || {};
  if (!fcmToken || !String(fcmToken).trim()) throw badRequest('fcmToken is required');
  if (String(fcmToken).length > 255) throw badRequest('fcmToken is too long');

  await user.update({ fcm_token: String(fcmToken).trim() });
  res.json({ ok: true });
});

// Remove this device's FCM token (e.g. on sign-out) so it stops receiving pushes.
export const unregisterFcmToken = asyncHandler(async (req, res) => {
  const user = await AppUser.findByPk(req.auth.sub);
  if (!user) throw unauthorized('User not found');
  await user.update({ fcm_token: null });
  res.json({ ok: true });
});

export const getAppProfile = asyncHandler(async (req, res) => {
  const user = await AppUser.findByPk(req.auth.sub);
  if (!user) throw unauthorized('User not found');
  res.json(toUser(user));
});

export const updateAppProfile = asyncHandler(async (req, res) => {
  const user = await AppUser.findByPk(req.auth.sub);
  if (!user) throw unauthorized('User not found');

  const { display_name } = req.body || {};
  const patch = {};
  if (display_name !== undefined) {
    const name = String(display_name).trim();
    if (!name) throw badRequest('Display name cannot be empty');
    patch.display_name = name.slice(0, 120);
  }

  await user.update(patch);
  res.json(toUser(user));
});

// ── Admin management (full CRUD) ──────────────────────────────────────────────

export const list = asyncHandler(async (req, res) => {
  const { status, q } = req.query;
  const where = {};

  if (status) where.status = status;
  if (q) {
    where[Op.or] = [
      { email: { [Op.like]: `%${q}%` } },
      { display_name: { [Op.like]: `%${q}%` } },
    ];
  }

  const users = await AppUser.findAll({
    where,
    order: [['created_at', 'DESC'], ['id', 'DESC']],
  });

  const rows = await Promise.all(users.map(withStats));
  res.json(rows);
});

export const getOne = asyncHandler(async (req, res) => {
  const user = await AppUser.findByPk(req.params.id);
  if (!user) throw notFound('User not found');

  const [lessonsDone, recent] = await Promise.all([
    LessonProgress.count({ where: { app_user_id: user.id } }),
    LessonProgress.findAll({
      where: { app_user_id: user.id },
      order: [['completed_at', 'DESC'], ['id', 'DESC']],
      limit: 10,
    }),
  ]);

  res.json({
    ...toUser(user),
    lessonsDone,
    firebaseUid: user.firebase_uid,
    recentLessons: recent.map(r => ({
      lessonId: r.lesson_id,
      mistakes: r.mistakes,
      xpEarned: r.xp_earned,
      completedAt: r.completed_at,
    })),
  });
});

// Create a learner manually (e.g. an email account provisioned by staff).
export const create = asyncHandler(async (req, res) => {
  const { email, display_name = '', password } = req.body || {};
  const cleanEmail = String(email || '').toLowerCase().trim();
  if (!cleanEmail) throw badRequest('email is required');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) throw badRequest('invalid email');

  const existing = await AppUser.findOne({ where: { email: cleanEmail } });
  if (existing) throw badRequest('a learner with this email already exists');

  let password_hash = null;
  if (password) {
    if (String(password).length < 8) throw badRequest('password must be at least 8 characters');
    password_hash = await bcrypt.hash(String(password), 12);
  }

  const user = await AppUser.create({
    email: cleanEmail,
    display_name: String(display_name).slice(0, 120),
    provider: 'email',
    status: 'active',
    password_hash,
  });

  console.log(`[users] admin created learner #${user.id} (${user.email})`);
  res.status(201).json(await withStats(user));
});

export const update = asyncHandler(async (req, res) => {
  const user = await AppUser.findByPk(req.params.id);
  if (!user) throw notFound('User not found');

  const { display_name, email, status, xp, hearts, streak } = req.body || {};
  const patch = {};

  if (display_name !== undefined) patch.display_name = String(display_name).slice(0, 120);

  if (email !== undefined) {
    const cleanEmail = String(email).toLowerCase().trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) throw badRequest('invalid email');
    const clash = await AppUser.findOne({ where: { email: cleanEmail, id: { [Op.ne]: user.id } } });
    if (clash) throw badRequest('another learner already uses this email');
    patch.email = cleanEmail;
  }

  if (status !== undefined) {
    if (!['active', 'banned'].includes(status)) throw badRequest('Invalid status');
    patch.status = status;
  }
  if (xp !== undefined) patch.xp = Math.max(0, Number(xp) || 0);
  if (hearts !== undefined) patch.hearts = Math.max(0, Math.min(5, Number(hearts) || 0));
  if (streak !== undefined) patch.streak = Math.max(0, Number(streak) || 0);

  await user.update(patch);
  console.log(`[users] admin updated learner #${user.id} — ${Object.keys(patch).join(', ') || 'no changes'}`);
  res.json(await withStats(user));
});

// Wipe a learner's learning history but keep the account.
export const resetProgress = asyncHandler(async (req, res) => {
  const user = await AppUser.findByPk(req.params.id);
  if (!user) throw notFound('User not found');

  const deleted = await LessonProgress.destroy({ where: { app_user_id: user.id } });
  await user.update({ xp: 0, hearts: 5, streak: 0 });

  console.log(`[users] admin reset progress for learner #${user.id} (${deleted} record(s) removed)`);
  res.json(await withStats(user));
});

export const remove = asyncHandler(async (req, res) => {
  const user = await AppUser.findByPk(req.params.id);
  if (!user) throw notFound('User not found');
  await user.destroy();
  console.log(`[users] admin deleted learner #${req.params.id}`);
  res.status(204).end();
});