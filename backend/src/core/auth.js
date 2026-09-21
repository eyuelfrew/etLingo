import jwt from 'jsonwebtoken';
import { asyncHandler, unauthorized, forbidden } from './http.js';

const secret = () => {
  const s = process.env.JWT_SECRET;
  if (!s) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('JWT_SECRET is required in production — refusing to start with a weak default');
    }
    console.warn('⚠️  JWT_SECRET not set — using insecure fallback (development only)');
    return 'change_me_in_production';
  }
  return s;
};

// ── Token issuing ─────────────────────────────────────────────────────────────
// Two token audiences: admin console tokens and mobile app-user tokens.
// In a microservice split these would be issued by the dedicated auth service.

export function signToken(admin) {
  return jwt.sign(
    { sub: admin.id, role: admin.role },
    secret(),
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
  );
}

export function signAppToken(user) {
  return jwt.sign(
    { sub: user.id, role: 'app_user' },
    secret(),
    { expiresIn: '30d' },
  );
}

function verify(token) {
  try {
    return jwt.verify(token, secret());
  } catch {
    throw unauthorized('Invalid or expired token');
  }
}

async function bearer(req) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) throw unauthorized('Missing bearer token');
  return verify(token);
}

// ── Admin console guard (auth module) ────────────────────────────────────────
export const requireAuth = asyncHandler(async (req, _res, next) => {
  const payload = await bearer(req);
  const { Admin } = await import('../modules/auth/auth.models.js');
  const admin = await Admin.findByPk(payload.sub);
  if (!admin) throw unauthorized('Account no longer exists');

  req.auth = { sub: admin.id, role: admin.role };
  next();
});

export const requireSuper = asyncHandler(async (req, _res, next) => {
  if (req.auth?.role !== 'super') throw forbidden('Super admin access required');
  next();
});

// ── Mobile app-user guard (users module) ─────────────────────────────────────
export const requireAppAuth = asyncHandler(async (req, _res, next) => {
  const payload = await bearer(req);
  if (payload.role !== 'app_user') throw unauthorized('Not an app user token');

  const { AppUser } = await import('../modules/users/users.models.js');
  const user = await AppUser.findByPk(payload.sub);
  if (!user) throw unauthorized('Account no longer exists');
  if (user.status === 'banned') throw unauthorized('Account has been suspended');

  req.auth = { sub: user.id, role: 'app_user' };
  next();
});