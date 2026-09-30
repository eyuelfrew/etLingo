import rateLimit from 'express-rate-limit';

/**
 * Global rate limiter — 100 requests per minute per IP.
 * Protects every API endpoint against abuse and DDoS.
 */
export const globalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100,
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' },
});

/**
 * Stricter limiter for auth-sensitive endpoints — 10 requests per minute per IP.
 * Use on login, password reset, token refresh, etc.
 */
export const authLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many auth attempts, please try again later' },
});

/** Write actions (comments, likes, stories) — 30/min per IP. */
export const writeLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many actions, please slow down' },
});

/** Content uploads — 20/min per IP. */
export const uploadLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many uploads, please try again later' },
});
