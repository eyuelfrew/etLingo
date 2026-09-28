import 'dotenv/config';
import path from 'path';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import routes from './routes/index.js';
import { errorHandler } from './core/http.js';
import { requestLogger, requestEcho, logHttpBanner } from './core/logger.js';
import { globalLimiter } from './middlewares/rateLimiter.js';
import { checkStatus, logStatus, getMysqlStatus, getRedisStatus } from './core/status.js';
import { getFirebaseStatus } from './core/firebase.js';
import { getS3Status } from './core/storage.js';
import { startCampaignWorker } from './modules/notifications/notifications.runner.js';
import { logFcmAvailability } from './modules/notifications/notifications.push.js';

const app = express();

// Global rate limit — 100 req/min per IP
app.use(globalLimiter);

// Security headers (helmet). CSP is disabled — this is a JSON API, not a page.
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// CORS — admin console (local + configured). Proxy same-origin requests skip CORS.
const allowedOrigins = new Set(
  [
    process.env.ADMIN_URL || 'http://localhost:5173',
    'http://localhost:5173',
    'http://127.0.0.1:5173',
    'http://localhost:5174',
    'http://127.0.0.1:5174',
  ].filter(Boolean),
);
app.use(cors({
  origin(origin, callback) {
    // Allow non-browser tools (no Origin header) and known admin origins.
    if (!origin || allowedOrigins.has(origin)) return callback(null, true);
    return callback(null, false);
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

// Body parsing — do not crash on empty/null JSON bodies.
app.use(express.json({ limit: '2mb', strict: false }));

// Request logging — morgan + [http] echo (always on; file + console).
app.use(requestLogger);
app.use(requestEcho);

// Health endpoint (no auth needed, no versioning)
app.get('/api/health', async (_req, res) => {
  const mysql = getMysqlStatus();
  const redis = getRedisStatus();
  const firebase = getFirebaseStatus();
  const s3 = getS3Status();
  const isOk = mysql === 'up';
  res.status(isOk ? 200 : 503).json({
    status: isOk ? 'ok' : 'degraded',
    service: 'etlingo-backend',
    mysql, redis, firebase, s3,
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

/**
 * Windows lets two processes bind the same port, so a second `npm start` /
 * `npm run dev` stays silent while the first one serves (and logs) all the
 * traffic. Say so out loud instead of looking like broken logging.
 */
async function warnIfPortAlreadyServed() {
  try {
    const res = await fetch(`http://127.0.0.1:${PORT}/api/health`, {
      signal: AbortSignal.timeout(800),
    });
    console.warn('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    console.warn(`  Another backend already answers on :${PORT} (${res.status}).`);
    console.warn('  Requests go to that process — this terminal will look silent.');
    console.warn('  Stop every other backend and keep only one running.');
    console.warn('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
  } catch {
    // Nothing listening — the normal case when starting fresh.
  }
}

await warnIfPortAlreadyServed();

app.listen(PORT, async () => {
  console.log('==========================================');
  console.log(`  EtLingo backend running at :${PORT}`);
  console.log(`  Health   http://localhost:${PORT}/api/health`);
  console.log(`  API v1   http://localhost:${PORT}/api/v1`);
  console.log('==========================================');
  logHttpBanner();
  await checkStatus();
  logStatus();
  logFcmAvailability();
  // Re-check periodically; logStatus reprints when Redis comes up after boot race.
  setInterval(async () => {
    await checkStatus();
    logStatus();
  }, 10_000);

  // Campaign worker — delivers scheduled notification rounds to learners.
  if (process.env.DISABLE_CAMPAIGN_WORKER !== '1') {
    startCampaignWorker(Number(process.env.CAMPAIGN_WORKER_INTERVAL_MS) || 15_000);
    console.log('  Worker   campaign runner every 15s');
  }
});
