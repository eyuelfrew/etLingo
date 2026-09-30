import { Router } from 'express';
import { requireAppAuth, requireAuth, optionalAppAuth } from '../../core/auth.js';
import { writeLimiter } from '../../middlewares/rateLimiter.js';
import {
  submitStory,
  listApprovedStories,
  myStories,
  adminListStories,
  adminModerateStory,
  exchangeSignup,
  myExchange,
  adminListExchange,
  adminUpdateExchange,
} from './community.controller.js';

const router = Router();

// Community stories
router.post('/app/stories', writeLimiter, requireAppAuth, submitStory);
router.get('/app/stories', optionalAppAuth, listApprovedStories);
router.get('/app/stories/mine', requireAppAuth, myStories);
router.get('/admin/stories', requireAuth, adminListStories);
router.put('/admin/stories/:id', requireAuth, adminModerateStory);

// Language exchange
router.post('/app/exchange/signup', writeLimiter, requireAppAuth, exchangeSignup);
router.get('/app/exchange/me', requireAppAuth, myExchange);
router.get('/admin/exchange', requireAuth, adminListExchange);
router.put('/admin/exchange/:id', requireAuth, adminUpdateExchange);

export default router;
