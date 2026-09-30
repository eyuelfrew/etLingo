import { Router } from 'express';
import { requireAuth, requireAppAuth } from '../../core/auth.js';
import {
  list, getOne, create, update, resetProgress, cancelSubscription, remove,
  registerFcmToken, unregisterFcmToken,
  getMyProgress, completeLesson, resetMyProgress,
} from './users.controller.js';

const router = Router();

// ── Admin learner management ──────────────────────────────────────────────────
// (App-user self-service profile routes live in the auth module's router.)
router.get('/admin/app-users', requireAuth, list);
router.post('/admin/app-users', requireAuth, create);
router.get('/admin/app-users/:id', requireAuth, getOne);
router.put('/admin/app-users/:id', requireAuth, update);
router.post('/admin/app-users/:id/reset-progress', requireAuth, resetProgress);
router.post('/admin/app-users/:id/cancel-subscription', requireAuth, cancelSubscription);
router.post('/admin/app-users/:id/cancel-subscription', requireAuth, cancelSubscription);
router.delete('/admin/app-users/:id', requireAuth, remove);

// ── App-user device push token (mobile app self-service) ──────────────────────
router.post('/app/devices/token', requireAppAuth, registerFcmToken);
router.delete('/app/devices/token', requireAppAuth, unregisterFcmToken);

// ── Learner progress (XP, streak, hearts, completed lessons) ──────────────────
router.get('/app/progress', requireAppAuth, getMyProgress);
router.post('/app/progress/lesson', requireAppAuth, completeLesson);
router.post('/app/progress/reset', requireAppAuth, resetMyProgress);

export default router;