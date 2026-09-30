import { Router } from 'express';
import { requireAuth, optionalAppAuth, requireAppAuth } from '../../core/auth.js';
import { writeLimiter } from '../../middlewares/rateLimiter.js';
import {
  listCategories, createCategory, updateCategory, deleteCategory,
  listWords, createWord, updateWord, deleteWord, bulkWords,
  appTopics, appTopicPack,
  markWordKnown, unmarkWordKnown, myTopicProgress,
} from './topics.controller.js';

const router = Router();

// App
router.get('/app/topics/:code', optionalAppAuth, appTopics);
router.get('/app/topics/:code/:slug', optionalAppAuth, appTopicPack);
router.get('/app/topics/progress', requireAppAuth, myTopicProgress);
router.post('/app/topics/words/:id/known', writeLimiter, requireAppAuth, markWordKnown);
router.delete('/app/topics/words/:id/known', writeLimiter, requireAppAuth, unmarkWordKnown);
router.post('/app/topics/words/:id/unmark', writeLimiter, requireAppAuth, unmarkWordKnown);

// Admin
router.get('/admin/topic-categories', requireAuth, listCategories);
router.post('/admin/topic-categories', requireAuth, createCategory);
router.put('/admin/topic-categories/:id', requireAuth, updateCategory);
router.delete('/admin/topic-categories/:id', requireAuth, deleteCategory);

router.get('/admin/topic-words', requireAuth, listWords);
router.post('/admin/topic-words', requireAuth, createWord);
router.put('/admin/topic-words/:id', requireAuth, updateWord);
router.delete('/admin/topic-words/:id', requireAuth, deleteWord);
router.post('/admin/topic-categories/:id/words/bulk', requireAuth, bulkWords);

export default router;
