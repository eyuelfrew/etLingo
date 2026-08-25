import morgan from 'morgan';

// Fields that must never reach the console.
const REDACTED_KEYS = new Set([
  'password', 'currentpassword', 'newpassword',
  'idtoken', 'token', 'authorization',
]);

// Who is making the request? Set later by the auth guards on req.auth.
morgan.token('who', (req) => {
  if (!req.auth) return 'anon';
  return req.auth.role === 'app_user'
    ? `user#${req.auth.sub}`
    : `admin#${req.auth.sub}/${req.auth.role}`;
});

// Short redacted body summary for mutating requests.
morgan.token('body', (req) => {
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) return '';
  const b = req.body;
  if (!b || typeof b !== 'object' || Object.keys(b).length === 0) return '';

  const safe = {};
  for (const [k, v] of Object.entries(b)) {
    safe[k] = REDACTED_KEYS.has(k.toLowerCase()) ? '•••' : v;
  }
  let s = JSON.stringify(safe);
  if (s.length > 140) s = `${s.slice(0, 137)}…`;
  return ` ${s}`;
});

const FORMAT = ':date[iso] :method :url → :status (:response-time ms) [:who]:body';

// One line per request. Skips CORS preflights to keep the console readable.
export const requestLogger = morgan(FORMAT, {
  skip: (req) => req.method === 'OPTIONS',
});