import morgan from 'morgan';

// Fields that must never reach the console.
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

const COMPACT = ':date[iso] :method :url → :status (:response-time ms) [:who]:body';

// teftef-style colored 'dev' by default; set MORGAN_FORMAT=compact for etLingo format.
const format = process.env.MORGAN_FORMAT === 'compact' ? COMPACT : 'dev';

/** Always log to stdout so the terminal (nodemon) shows every request. */
export const requestLogger = morgan(format, {
  skip: (req) => req.method === 'OPTIONS',
  stream: process.stdout,
});

/** Extra [http] line — easy to spot in a busy nodemon window. */
export function requestEcho(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    const ms = Date.now() - start;
    const who = req.auth
      ? (req.auth.role === 'app_user'
          ? `user#${req.auth.sub}`
          : `admin#${req.auth.sub}/${req.auth.role}`)
      : 'anon';
    console.log(
      `[http] ${req.method} ${req.originalUrl} → ${res.statusCode} (${ms}ms) ${who}`,
    );
  });
  next();
}

export default requestLogger;
