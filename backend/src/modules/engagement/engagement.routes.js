import { Router } from 'express';
import { requireAppAuth, requireAuth, optionalAppAuth } from '../../core/auth.js';
import {
  getUnitEngagement,
  getLanguageEngagement,
  likeUnit,
  likeLanguage,
  commentOnUnit,
  commentOnLanguage,
  adminUnitEngagement,
  adminLanguageEngagement,
  getCultureUnitEngagement,
  likeCultureUnit,
  commentOnCultureUnit,
  adminCultureUnitEngagement,
} from './engagement.controller.js';

const router = Router();

router.get('/app/engagement/units/:id', optionalAppAuth, getUnitEngagement);
router.get('/app/engagement/languages/:id', optionalAppAuth, getLanguageEngagement);

router.post('/app/engagement/units/:id/like', requireAppAuth, likeUnit);
router.post('/app/engagement/languages/:id/like', requireAppAuth, likeLanguage);
router.post('/app/engagement/units/:id/comments', requireAppAuth, commentOnUnit);
router.post('/app/engagement/languages/:id/comments', requireAppAuth, commentOnLanguage);

router.get('/app/engagement/culture-units/:id', optionalAppAuth, getCultureUnitEngagement);
router.post('/app/engagement/culture-units/:id/like', requireAppAuth, likeCultureUnit);
router.post('/app/engagement/culture-units/:id/comments', requireAppAuth, commentOnCultureUnit);

router.get('/admin/engagement/units/:id', requireAuth, adminUnitEngagement);
router.get('/admin/engagement/languages/:id', requireAuth, adminLanguageEngagement);
router.get('/admin/engagement/culture-units/:id', requireAuth, adminCultureUnitEngagement);

export default router;
