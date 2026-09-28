import { Router } from 'express';
import { requireAuth, optionalAppAuth, requireAppAuth } from '../../core/auth.js';
import {
  adminListAds, adminCreateAd, adminUpdateAd, adminDeleteAd,
  appAd, appAds, adClick, adminPositions,
} from './ads.controller.js';

const router = Router();

// App
router.get('/app/ads', optionalAppAuth, appAds);
router.get('/app/ads/slot', optionalAppAuth, appAd);
router.post('/app/ads/:id/click', optionalAppAuth, adClick);

// Admin
router.get('/admin/ads', requireAuth, adminListAds);
router.get('/admin/ads/positions', requireAuth, adminPositions);
router.post('/admin/ads', requireAuth, adminCreateAd);
router.put('/admin/ads/:id', requireAuth, adminUpdateAd);
router.delete('/admin/ads/:id', requireAuth, adminDeleteAd);

export default router;
