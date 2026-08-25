import bcrypt from 'bcryptjs';
import { Admin } from './auth.models.js';
import { signToken } from '../../core/auth.js';

function publicAdmin(admin) {
  const row = admin.toJSON();
  delete row.password_hash;
  return row;
}

// ── Admin console auth ────────────────────────────────────────────────────────
export async function login(req, res) {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'email and password required' });

  const admin = await Admin.findOne({ where: { email: email.toLowerCase().trim() } });
  if (!admin) return res.status(401).json({ error: 'invalid credentials' });

  const ok = await bcrypt.compare(password, admin.password_hash);
  if (!ok) return res.status(401).json({ error: 'invalid credentials' });

  const token = signToken(admin);
  res.json({ token, ...publicAdmin(admin) });
}

export async function me(req, res) {
  const admin = await Admin.findByPk(req.auth.sub);
  if (!admin) return res.status(401).json({ error: 'admin no longer exists' });
  res.json(publicAdmin(admin));
}

export async function createAdmin(req, res) {
  // Only super admins can create new admins
  if (req.auth.role !== 'super') {
    return res.status(403).json({ error: 'only super admins can create users' });
  }

  const { name, email, password, role } = req.body;
  if (!name || !email || !password) return res.status(400).json({ error: 'name, email and password required' });
  if (password.length < 8) return res.status(400).json({ error: 'password must be at least 8 characters' });

  const existing = await Admin.findOne({ where: { email: email.toLowerCase().trim() } });
  if (existing) return res.status(409).json({ error: 'email already registered' });

  const hash = await bcrypt.hash(password, 12);
  const admin = await Admin.create({
    name,
    email: email.toLowerCase().trim(),
    password_hash: hash,
    role: role || 'editor',
  });

  const token = signToken(admin);
  res.status(201).json({ token, ...publicAdmin(admin) });
}

export async function changePassword(req, res) {
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword) return res.status(400).json({ error: 'currentPassword and newPassword required' });
  if (newPassword.length < 8) return res.status(400).json({ error: 'new password must be at least 8 characters' });

  const admin = await Admin.findByPk(req.auth.sub);
  if (!admin) return res.status(401).json({ error: 'admin not found' });

  const ok = await bcrypt.compare(currentPassword, admin.password_hash);
  if (!ok) return res.status(401).json({ error: 'current password is incorrect' });

  const hash = await bcrypt.hash(newPassword, 12);
  await admin.update({ password_hash: hash });

  res.json({ message: 'password updated' });
}

// Simple in-memory rate limiter for login attempts
const loginAttempts = new Map();
const MAX_ATTEMPTS = 5;
const WINDOW_MS = 15 * 60 * 1000; // 15 minutes

export function checkLoginRateLimit(email) {
  const key = email.toLowerCase().trim();
  const now = Date.now();
  const record = loginAttempts.get(key);

  if (!record || now - record.first > WINDOW_MS) {
    loginAttempts.set(key, { count: 1, first: now });
    return { ok: true, remaining: MAX_ATTEMPTS - 1 };
  }

  record.count++;
  if (record.count > MAX_ATTEMPTS) {
    const retryAfter = Math.ceil((record.first + WINDOW_MS - now) / 60000);
    return { ok: false, retryAfter };
  }

  return { ok: true, remaining: MAX_ATTEMPTS - record.count };
}

// Clean up old entries every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, record] of loginAttempts) {
    if (now - record.first > WINDOW_MS) loginAttempts.delete(key);
  }
}, 5 * 60 * 1000);

// ── Mobile app auth (Firebase ID token → app session JWT) ────────────────────
// NOTE: touches the users module's AppUser table to provision the account on
// first sign-in. In a microservice split, this becomes a call/event to the
// user service instead of a direct model write.
import { AppUser } from '../users/users.models.js';
import { signAppToken } from '../../core/auth.js';
import { adminAuth, getFirebaseStatus } from '../../core/firebase.js';
import { asyncHandler, badRequest, forbidden, unauthorized } from '../../core/http.js';

function serializeUser(user) {
  return {
    id: user.id,
    email: user.email,
    displayName: user.display_name,
    status: user.status,
    provider: user.provider,
    xp: user.xp,
    hearts: user.hearts,
    streak: user.streak,
  };
}

export const googleSignIn = asyncHandler(async (req, res) => {
  const { idToken } = req.body || {};
  if (!idToken) throw badRequest('Missing idToken');

  const status = getFirebaseStatus();
  if (!status.initialized) {
    throw badRequest('Firebase not configured on server');
  }

  let decoded;
  try {
    decoded = await adminAuth.verifyIdToken(idToken);
    console.log(`[Firebase Auth] ✓ ID token verified for uid=${decoded.uid} email=${decoded.email}`);
  } catch (err) {
    console.error(`[Firebase Auth] ✗ ID token verification failed: ${err.message}`);
    throw unauthorized('Invalid or expired Firebase token');
  }

  const [user, created] = await AppUser.findOrCreate({
    where: { firebase_uid: decoded.uid },
    defaults: {
      firebase_uid: decoded.uid,
      email: decoded.email || null,
      display_name: decoded.name || decoded.email?.split('@')[0] || 'Learner',
      provider: 'google',
    },
  });

  if (user.status === 'banned') {
    throw forbidden('This account has been suspended');
  }

  if (created) {
    console.log(`[Firebase Auth] ✓ New app user created: id=${user.id} email=${user.email}`);
  } else {
    if (decoded.email && user.email !== decoded.email) {
      await user.update({ email: decoded.email });
    }
    if (decoded.name && user.display_name !== decoded.name) {
      await user.update({ display_name: decoded.name });
    }
    console.log(`[Firebase Auth] ✓ Existing app user loaded: id=${user.id} email=${user.email}`);
  }

  const token = signAppToken(user);
  console.log(`[Firebase Auth] ✓ Session JWT issued for user=${user.id}`);

  res.json({ token, user: serializeUser(user) });
});