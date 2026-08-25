import { Router } from 'express';
import { buildModuleRouters } from '../modules/index.js';
import { checkStatus, getMysqlStatus, getRedisStatus } from '../core/status.js';
import { getFirebaseStatus } from '../core/firebase.js';

// Compatibility composition root. All real routing lives inside
// src/modules/*/<name>.routes.js — this file only mounts them and keeps the
// non-module health endpoints so existing clients are unaffected.
const router = buildModuleRouters();

// Health + diagnostics (kept at their original paths)
router.get('/health', async (_req, res) => {
  const mysql = getMysqlStatus();
  const redis = getRedisStatus();
  const firebase = getFirebaseStatus();
  const isOk = mysql === 'up';
  res.status(isOk ? 200 : 503).json({
    status: isOk ? 'ok' : 'degraded',
    service: 'etlingo-backend',
    mysql, redis, firebase,
    time: new Date().toISOString(),
  });
});

router.get('/status', async (_req, res) => {
  res.json({ mysql: getMysqlStatus(), redis: getRedisStatus(), firebase: getFirebaseStatus() });
});

router.post('/status/refresh', async (_req, res) => {
  await checkStatus();
  res.json({ mysql: getMysqlStatus(), redis: getRedisStatus() });
});

export default router;
