import { Router } from 'express';
import { requireAuth, optionalAppAuth } from '../../core/auth.js';
import {
  listCategories, createCategory, updateCategory, deleteCategory,
  listWords, createWord, updateWord, deleteWord, bulkWords,
  appTopics, appTopicPack,
} from './topics.controller.js';

const router = Router();

// App
router.get('/app/topics/:code', optionalAppAuth, appTopics);
router.get('/app/topics/:code/:slug', optionalAppAuth, appTopicPack);

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
