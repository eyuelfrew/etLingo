import { Router } from 'express';
import { requireAuth, optionalAppAuth } from '../../core/auth.js';
import {
  listScripts, getScript, createScript, updateScript, deleteScript,
  listLetters, createLetter, updateLetter, deleteLetter, bulkUpsertLetters, reorderLetters,
  listLanguageScripts, mapLanguageScript, unmapLanguageScript,
  appScripts, appScriptLetters,
  languageScriptsBundle, createScriptForLanguage,
} from './scripts.controller.js';

const router = Router();

// App (learner)
router.get('/app/scripts', optionalAppAuth, appScripts);
router.get('/app/scripts/:code/letters', optionalAppAuth, appScriptLetters);

// Admin — language-first: scripts owned by / created for a language
router.get('/admin/languages/:id/scripts', requireAuth, languageScriptsBundle);
router.post('/admin/languages/:id/scripts', requireAuth, createScriptForLanguage);

// Admin — scripts (writing systems)
router.get('/admin/scripts', requireAuth, listScripts);
router.get('/admin/scripts/:id', requireAuth, getScript);
router.post('/admin/scripts', requireAuth, createScript);
router.put('/admin/scripts/:id', requireAuth, updateScript);
router.delete('/admin/scripts/:id', requireAuth, deleteScript);

// Admin — alphabet letters
router.get('/admin/script-letters', requireAuth, listLetters);
router.post('/admin/script-letters', requireAuth, createLetter);
router.put('/admin/script-letters/:id', requireAuth, updateLetter);
router.delete('/admin/script-letters/:id', requireAuth, deleteLetter);
router.post('/admin/scripts/:id/letters/bulk', requireAuth, bulkUpsertLetters);
router.post('/admin/script-letters/reorder', requireAuth, reorderLetters);

// Admin — language ↔ script
router.get('/admin/language-scripts', requireAuth, listLanguageScripts);
router.post('/admin/language-scripts', requireAuth, mapLanguageScript);
router.delete('/admin/language-scripts/:id', requireAuth, unmapLanguageScript);

export default router;
