# Security hardening (etLingo)

Implemented hardening — keep this in mind before production.

## What we enforce

| Area | Control |
| --- | --- |
| **JWT** | `iss` + `aud` (`admin` vs `app`), admin TTL **12h**, app 30d, `token_version` invalidates sessions after password change |
| **JWT_SECRET** | Required in production, **≥ 32 chars** |
| **Passwords** | bcrypt(12); production: ≥10 chars, mixed case + digit, reject `admin123`/`password`… |
| **Login** | Per-email limiter (5 / 15 min) + IP `authLimiter` (10 / min); uniform 401 |
| **Rate limits** | Global 100/min · auth 10/min · writes 30/min · uploads 20/min |
| **XSS** | Comments / stories sanitized (strip tags, `javascript:`, control chars) |
| **500s** | Generic message in production (no stack leak) |
| **Headers** | Helmet, HSTS in prod, `Referrer-Policy: no-referrer` |
| **CORS** | Allowlist (admin origins only) |
| **Uploads** | MIME allowlist + random filenames (no path reuse) |
| **Secrets** | `.env`, `*-firebase-adminsdk-*.json`, `s3-strag.md` gitignored |

## Before production

1. Set `JWT_SECRET` to a long random value (`openssl rand -hex 32`).
2. Change the default admin password (`admin@etlang.app / admin123`).
3. Set `NODE_ENV=production`.
4. Restrict `ADMIN_URL` / CORS to the real console origin.
5. Put TLS in front (or rely on HSTS via a reverse proxy).
6. Rotate any keys that were ever committed or shared in chat (Firebase / S3).

## Still worth doing later

- Refresh tokens + revocation list (instead of long-lived app JWTs)
- 2FA for super admins
- CSP if you ever serve HTML from this origin
- Automated dependency / secret scanning in CI
- WAF / IP allowlist for `/admin/*` if console is public
