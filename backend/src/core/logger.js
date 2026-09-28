import fs from 'fs';
import path from 'path';
import morgan from 'morgan';

/**
 * Request logging is a development convenience: the access log is useful while
 * building, but in production it floods the platform log stream (and echoes
 * request bodies), so it is disabled when NODE_ENV=production.
 */
export const nodeEnv = process.env.NODE_ENV || 'development';
/** Always log HTTP in this project — user expects teftef-style access logs. */
export const isDev = process.env.DISABLE_HTTP_LOG !== '1';

const REDACTED_KEYS = new Set([
  'password', 'currentpassword', 'newpassword',
  'idtoken', 'token', 'authorization', 'secret', 'accesstoken',
]);

morgan.token('who', (req) => {
  if (!req.auth) return 'anon';
  return req.auth.role === 'app_user'
    ? `user#${req.auth.sub}`
    : `admin#${req.auth.sub}/${req.auth.role}`;
});

morgan.token('body', (req) => {
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) return '';
  const b = req.body;
  if (!b || typeof b !== 'object' || Object.keys(b).length === 0) return '';
  const safe = {};
  for (const [k, v] of Object.entries(b)) {
    safe[k] = REDACTED_KEYS.has(String(k).toLowerCase()) ? '•••' : v;
  }
  let s = JSON.stringify(safe);
  if (s.length > 140) s = `${s.slice(0, 137)}…`;
  return ` ${s}`;
});

/** compact = one etLingo line; any other value is passed through to morgan ('dev', 'combined', …). */
const COMPACT = ':date[iso] :method :url → :status (:response-time ms) [:who]:body';
const FORMAT = process.env.MORGAN_FORMAT === 'compact'
  ? COMPACT
  : (process.env.MORGAN_FORMAT || 'dev');

/** Dev-only access log file; nothing is written on disk in production. */
export const HTTP_LOG_PATH = path.resolve(
  process.cwd(),
  process.env.HTTP_LOG_FILE || 'logs/http-access.log',
);

let fileStream = null;
try {
  fs.mkdirSync(path.dirname(HTTP_LOG_PATH), { recursive: true });
  fileStream = fs.createWriteStream(HTTP_LOG_PATH, { flags: 'a' });
} catch (e) {
  console.error(`[logger] cannot open ${HTTP_LOG_PATH}: ${e.message}`);
}

/** In dev, write every access line to BOTH the console and the log file. */
const tee = {
  write(str) {
    try {
      process.stdout.write(str);
    } catch (_) {}
    try {
      fileStream?.write(str);
    } catch (_) {}
  },
};

/** morgan — teftef-style 'dev' lines on stdout + file. */
export const requestLogger = morgan(FORMAT, {
  skip: (req) => req.method === 'OPTIONS',
  stream: tee,
});

/** Extra [http] line — obvious even if colors are stripped. */
export function requestEcho(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    const ms = Date.now() - start;
    const who = req.auth
      ? (req.auth.role === 'app_user'
          ? `user#${req.auth.sub}`
          : `admin#${req.auth.sub}/${req.auth.role}`)
      : 'anon';
    const line = `[http] ${req.method} ${req.originalUrl} → ${res.statusCode} (${ms}ms) ${who}\n`;
    tee.write(line);
  });
  return next();
}

export function logHttpBanner() {
  console.log('------------------------------------------');
  console.log(`  HTTP logging: morgan '${process.env.MORGAN_FORMAT || FORMAT}' + [http] echo`);
  console.log('  Console : this terminal (npm run dev)');
  console.log(`  File    : ${HTTP_LOG_PATH}`);
  console.log('------------------------------------------');
}

export default requestLogger;
