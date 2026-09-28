import { Router } from 'express';
import { requireAuth, requireAppAuth, optionalAppAuth } from '../../core/auth.js';
import {
  adminListUnits, adminCreateUnit, adminUpdateUnit, adminDeleteUnit,
  adminListCards, adminCreateCard, adminUpdateCard, adminDeleteCard,
  cultureBootstrap, proverbOfDay, completeCard, myCultureProgress, cultureCalendar,
} from './culture.controller.js';

const router = Router();

// Public (app) — static paths before :code
router.get('/app/culture/proverb/:code', optionalAppAuth, proverbOfDay);
router.get('/app/culture/calendar', optionalAppAuth, cultureCalendar);
router.get('/app/culture/progress', requireAppAuth, myCultureProgress);
router.post('/app/culture/cards/:id/complete', requireAppAuth, completeCard);
router.get('/app/culture/:code', optionalAppAuth, cultureBootstrap);

// Admin
router.get('/admin/culture-units', requireAuth, adminListUnits);
router.post('/admin/culture-units', requireAuth, adminCreateUnit);
router.put('/admin/culture-units/:id', requireAuth, adminUpdateUnit);
router.delete('/admin/culture-units/:id', requireAuth, adminDeleteUnit);

router.get('/admin/culture-cards', requireAuth, adminListCards);
router.post('/admin/culture-cards', requireAuth, adminCreateCard);
router.put('/admin/culture-cards/:id', requireAuth, adminUpdateCard);
router.delete('/admin/culture-cards/:id', requireAuth, adminDeleteCard);

export default router;
