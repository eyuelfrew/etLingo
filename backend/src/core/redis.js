import Redis from 'ioredis';
import 'dotenv/config';

export const redisEnabled = Boolean(process.env.REDIS_URL);

let client = null;

if (redisEnabled) {
  client = new Redis(process.env.REDIS_URL, {
    lazyConnect: true,
    enableOfflineQueue: true,
    maxRetriesPerRequest: null,
    retryStrategy: (times) => Math.min(times * 500, 5000),
  });

  client.on('error', () => {});
  client.connect().catch(() => {});
}

export async function pingRedis() {
  if (!client || !redisEnabled) return 'disabled';
  try {
    await client.ping();
    return 'up';
  } catch {
    return 'down';
  }
}

export async function cacheGet(key) {
  if (!client || !redisEnabled) return null;
  try {
    return await client.get(key);
  } catch {
    return null;
  }
}

export async function cacheSet(key, value, ttlSeconds = 60) {
  if (!client || !redisEnabled) return false;
  try {
    await client.set(key, value, 'EX', ttlSeconds);
    return true;
  } catch {
    return false;
  }
}

export default client;