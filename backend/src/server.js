import 'dotenv/config';
import path from 'path';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import routes from './routes/index.js';
import { errorHandler } from './core/http.js';
import { requestLogger } from './core/logger.js';
import { checkStatus, logStatus, getMysqlStatus, getRedisStatus } from './core/status.js';
import { getFirebaseStatus } from './core/firebase.js';
import { startCampaignWorker } from './modules/notifications/notifications.runner.js';
import { logFcmAvailability } from './modules/notifications/notifications.push.js';

const app = express();

// Security headers (helmet). CSP is disabled — this is a JSON API, not a page.
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// CORS — allow the admin frontend origin (local dev + deployable via ADMIN_URL).
const adminOrigin = process.env.ADMIN_URL || 'http://localhost:5173';
app.use(cors({
  origin: adminOrigin,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

// Body parsing with size limit
app.use(express.json({ limit: '2mb' }));

// Request logging — one line per call:
// [iso-date] METHOD /path → status (ms) [who] {redacted body}
// Placed after express.json so mutating requests can show their payload.
app.use(requestLogger);

// Health endpoint (no auth needed, no versioning)
app.get('/api/health', async (_req, res) => {
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

// API v1 routes
app.use('/api/v1', routes);

// Uploaded pronunciation clips (admin-managed), served publicly to the apps.
app.use('/audio', express.static(path.resolve(process.cwd(), 'uploads', 'audio'), {
  maxAge: '30d',
  immutable: true,
}));

// 404 catch-all
app.use((_req, res) => res.status(404).json({ error: 'Route not found' }));

// Error handler
app.use(errorHandler);

const PORT = Number(process.env.PORT || 5050);
app.listen(PORT, async () => {
  console.log('==========================================');
  console.log(`  EtLingo backend running at :${PORT}`);
  console.log(`  Health   http://localhost:${PORT}/api/health`);
  console.log(`  API v1   http://localhost:${PORT}/api/v1`);
  console.log('==========================================');
  await checkStatus();
  logStatus();
  logFcmAvailability();
  setInterval(async () => { await checkStatus(); }, 30_000);

  // Campaign worker — delivers scheduled notification rounds to learners.
  if (process.env.DISABLE_CAMPAIGN_WORKER !== '1') {
    startCampaignWorker(Number(process.env.CAMPAIGN_WORKER_INTERVAL_MS) || 15_000);
    console.log('  Worker   campaign runner every 15s');
  }
});
