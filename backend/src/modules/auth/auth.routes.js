import { Router } from 'express';
import {
  login, me, createAdmin, changePassword, checkLoginRateLimit, googleSignIn,
} from './auth.controller.js';
import { requireAuth, requireAppAuth } from '../../core/auth.js';
import { getAppProfile, updateAppProfile } from '../users/users.controller.js';

const router = Router();

// ── Admin console auth ────────────────────────────────────────────────────────
router.post('/auth/login', (req, res, next) => {
  const { email } = req.body || {};
  if (!email) return next();

  const limit = checkLoginRateLimit(email);
  if (!limit.ok) {
    return res.status(429).json({
      error: `too many login attempts — try again in ${limit.retryAfter} minutes`,
    });
  }
  next();
}, login);

router.get('/auth/me', requireAuth, me);
router.post('/auth/create-admin', requireAuth, createAdmin);
router.post('/auth/change-password', requireAuth, changePassword);

// ── Mobile app session ────────────────────────────────────────────────────────
router.post('/app/auth/google', googleSignIn);
router.get('/app/auth/profile', requireAppAuth, getAppProfile);
router.put('/app/auth/profile', requireAppAuth, updateAppProfile);

export default router;