import Redis from 'ioredis';
import 'dotenv/config';

// Same URL shape as teftef services (127.0.0.1 avoids Windows localhost/IPv6 quirks).
const REDIS_URL = process.env.REDIS_URL || 'redis://127.0.0.1:6379';

export const redisEnabled = Boolean(process.env.REDIS_URL || true);

let client = null;

if (redisEnabled) {
  client = new Redis(REDIS_URL, {
    lazyConnect: true,
    enableOfflineQueue: true,
    maxRetriesPerRequest: null,
    connectTimeout: 5000,
    retryStrategy: (times) => Math.min(times * 500, 5000),
  });

  client.on('connect', () => {
    console.log(`[redis] connecting → ${REDIS_URL}`);
  });
  client.on('ready', () => {
    console.log(`[redis] ✓ ready (${REDIS_URL})`);
  });
  client.on('error', (err) => {
    console.error(`[redis] ✗ ${err.message}`);
  });
  client.on('close', () => {
    console.warn('[redis] connection closed — retrying…');
  });

  client.connect().catch((err) => {
    console.error(`[redis] initial connect failed: ${err.message}`);
  });
}

/** Force a live PING — truth, not just the client status field. */
export async function pingRedis() {
  if (!client) return 'disabled';
  try {
    if (client.status === 'wait' || client.status === 'end') {
      await client.connect();
    }
    await client.ping();
    return 'up';
  } catch {
    return 'down';
  }
}

export async function cacheGet(key) {
  if (!client) return null;
  try {
    return await client.get(key);
  } catch {
    return null;
  }
}

export async function cacheSet(key, value, ttlSeconds = 60) {
  if (!client) return false;
  try {
    await client.set(key, value, 'EX', ttlSeconds);
    return true;
  } catch {
    return false;
  }
}

export default client;
