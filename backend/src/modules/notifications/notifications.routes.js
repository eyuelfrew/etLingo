import { Router } from 'express';
import { requireAppAuth, requireAuth } from '../../core/auth.js';
import {
  send, adminList, adminRemove, listMine, markRead,
  createCampaign, listCampaigns, cancelCampaign, removeCampaign,
} from './notifications.controller.js';
import { getMyPreferences, updateMyPreferences } from './notifications.preferences.js';

const router = Router();

// ── App user inbox ────────────────────────────────────────────────────────────
router.get('/app/notifications', requireAppAuth, listMine);
router.post('/app/notifications/:id/read', requireAppAuth, markRead);

// ── App user notification preferences (opt-in/out per category) ───────────────
router.get('/app/notifications/preferences', requireAppAuth, getMyPreferences);
router.put('/app/notifications/preferences', requireAppAuth, updateMyPreferences);

// ── Admin: instant sends ──────────────────────────────────────────────────────
router.get('/admin/notifications', requireAuth, adminList);
router.post('/admin/notifications', requireAuth, send);
router.delete('/admin/notifications/:id', requireAuth, adminRemove);

// ── Admin: scheduled batch campaigns ─────────────────────────────────────────
router.get('/admin/campaigns', requireAuth, listCampaigns);
router.post('/admin/campaigns', requireAuth, createCampaign);
router.post('/admin/campaigns/:id/cancel', requireAuth, cancelCampaign);
router.delete('/admin/campaigns/:id', requireAuth, removeCampaign);

export default router;