import { sequelize } from './db.js';

let mysqlStatus = 'checking';
let mysqlHint = '';
let redisStatus = 'checking';
let redisHint = '';
let logged = false;
let lastLoggedRedis = null;

export function getMysqlStatus() { return mysqlStatus; }
export function getRedisStatus() { return redisStatus; }
export function getMysqlHint() { return mysqlHint; }
export function getRedisHint() { return redisHint; }

async function checkMysql() {
  try {
    await sequelize.authenticate();
    mysqlStatus = 'up';
    mysqlHint = '';
  } catch (e) {
    mysqlStatus = 'down';
    const code = e.original?.code || e.code || '';
    if (code === 'ECONNREFUSED') {
      mysqlHint = 'MySQL is not running — start it and try again';
    } else if (code === 'ER_ACCESS_DENIED_ERROR') {
      mysqlHint = 'Wrong user/password in .env — check DB_USER and DB_PASS';
    } else if (code === 'ER_BAD_DB_ERROR') {
      mysqlHint = 'Database does not exist yet — run: npm run db:init';
    } else {
      mysqlHint = e.message;
    }
  }
}

async function checkRedis() {
  try {
    const mod = await import('./redis.js');
    const pingRedis = mod.pingRedis;
    const redisEnabled = mod.redisEnabled;
    const redis = mod.default;

    if (!redisEnabled || !redis) {
      redisStatus = 'disabled';
      redisHint = '';
      return;
    }

    // Live PING — boot races (lazyConnect still connecting) no longer look like offline.
    const result = await pingRedis();
    if (result === 'up') {
      redisStatus = 'up';
      redisHint = '';
    } else if (result === 'disabled') {
      redisStatus = 'disabled';
      redisHint = '';
    } else {
      redisStatus = 'down';
      redisHint = 'Redis not reachable (optional — app works without it)';
    }
  } catch {
    redisStatus = 'down';
    redisHint = 'Redis not available (optional — app works without it)';
  }
}

export async function checkStatus() {
  await Promise.all([checkMysql(), checkRedis()]);
}

function desc(label, status, hint) {
  const icon =
    status === 'up' ? 'UP'
    : status === 'down' ? 'OFFLINE'
    : status === 'disabled' ? 'DISABLED (no REDIS_URL)'
    : '...';
  const extra = hint ? ` — ${hint}` : '';
  return `${label} ${icon}${extra}`;
}

export function logStatus() {
  const line = `[db] ${desc('MySQL', mysqlStatus, mysqlHint)} | ${desc('Redis', redisStatus, redisHint)}`;
  // Log boot once, then log again whenever Redis recovers/changes.
  if (!logged || redisStatus !== lastLoggedRedis) {
    logged = true;
    lastLoggedRedis = redisStatus;
    console.log(line);
  }
}
