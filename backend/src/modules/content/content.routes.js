import { Router } from 'express';
import { requireAuth } from '../../core/auth.js';
import {
  languages, units, lessons, questions, phrases, baseLanguages,
  dashboardStats, appLanguages, bootstrap, languagePhrases, appBaseLanguages,
} from './content.controller.js';
import { uploadAudio, uploadMedia } from './media.controller.js';
import { listObjects, getStorageStatus } from './storage.controller.js';

const router = Router();

// ── Public (mobile app) ───────────────────────────────────────────────────────
router.get('/app/languages', appLanguages);
router.get('/app/base-languages', appBaseLanguages);
router.get('/app/bootstrap/:code', bootstrap);
router.get('/app/:code/phrases', languagePhrases);

// ── Admin content management ──────────────────────────────────────────────────
router.get('/admin/stats', requireAuth, dashboardStats);

router.get('/admin/languages', requireAuth, languages.list);
router.get('/admin/languages/:id', requireAuth, languages.getOne);
router.post('/admin/languages', requireAuth, languages.create);
router.put('/admin/languages/:id', requireAuth, languages.update);
router.delete('/admin/languages/:id', requireAuth, languages.remove);

router.get('/admin/units', requireAuth, units.list);
router.post('/admin/units', requireAuth, units.create);
router.put('/admin/units/:id', requireAuth, units.update);
router.delete('/admin/units/:id', requireAuth, units.remove);

router.get('/admin/lessons', requireAuth, lessons.list);
router.post('/admin/lessons', requireAuth, lessons.create);
router.put('/admin/lessons/:id', requireAuth, lessons.update);
router.delete('/admin/lessons/:id', requireAuth, lessons.remove);

router.get('/admin/questions', requireAuth, questions.list);
router.post('/admin/questions', requireAuth, questions.create);
router.put('/admin/questions/:id', requireAuth, questions.update);
router.delete('/admin/questions/:id', requireAuth, questions.remove);

router.get('/admin/phrases', requireAuth, phrases.list);
router.post('/admin/phrases', requireAuth, phrases.create);
router.put('/admin/phrases/:id', requireAuth, phrases.update);
router.delete('/admin/phrases/:id', requireAuth, phrases.remove);

router.get('/admin/base-languages', requireAuth, baseLanguages.list);
router.get('/admin/base-languages/:id', requireAuth, baseLanguages.getOne);
router.post('/admin/base-languages', requireAuth, baseLanguages.create);
router.put('/admin/base-languages/:id', requireAuth, baseLanguages.update);
router.delete('/admin/base-languages/:id', requireAuth, baseLanguages.remove);

router.post('/admin/audio', requireAuth, ...uploadAudio);
router.post('/admin/media', requireAuth, ...uploadMedia);
router.get('/admin/storage', requireAuth, getStorageStatus);
router.get('/admin/storage/objects', requireAuth, listObjects);

export default router;