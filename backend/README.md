# EtLang Backend

Node.js + Express + MySQL content API for the ኢትLang app.
Admins manage courses here; the Flutter mobile app reads them.

## Setup

1. Install MySQL and make sure it's running.
2. Create your env file:

   ```bash
   cp .env.example .env
   ```

3. Create schema + seed admin + starter languages:

   ```bash
   npm install
   npm run db:init
   ```

4. Start the API:

   ```bash
   npm run dev        # nodemon · http://localhost:5050
   ```

Default admin login (change in production!): `admin@etlang.app` / `admin123`

## Service status logging

On boot the console reports both services, e.g.:

```
==========================================
  EtLang backend running at :5050
==========================================
  MySQL : [OFFLINE] start MySQL, then run npm run db:init
  Redis : [OK] connected (redis://localhost:6379)
```

- **MySQL** — pool status checked at startup and every 30s; transitions are
  logged by the monitor (`[monitor] MySQL went DOWN` / `is back UP [OK]`).
- **Redis** — optional. Set `REDIS_URL` in `.env` (e.g. `redis://localhost:6379`).
  Without it the API logs `[DISABLED]` and keeps working. When configured but
  unreachable it retries automatically and logs `[UNREACHABLE]`.
- `/api/health` returns live status for both:
  `{"mysql":"down","redis":"up"}`

A tiny cache helper is available at `src/config/redis.js`
(`cacheGet`/`cacheSet`) ready for future use.

## Endpoints

### Auth
| Method | Path | Notes |
| --- | --- | --- |
| POST | `/api/auth/login` | `{email, password}` → `{token, admin}` |
| GET | `/api/auth/me` | requires Bearer token |
| POST | `/api/auth/admins` | create admin (requires token) |

### Admin CRUD (all require Bearer token)
Full list/create/read/update/delete on:

- `/api/admin/languages`
- `/api/admin/units`
- `/api/admin/lessons`
- `/api/admin/questions`
- `/api/admin/phrases`
- `/api/admin/stats` — dashboard counters

Question JSON fields: `options`, `match_left`, `match_right`.

### Mobile app (public)
| Method | Path | Returns |
| --- | --- | --- |
| GET | `/api/app/bootstrap/:code` | language + units → lessons → questions tree |
| GET | `/api/app/:code/phrases` | phrasebook rows |

## Schema

`db/schema.sql` — admins, languages, units, lessons, questions,
phrases, app_users, lesson_progress. Mirrors the Flutter data model
(`Language → Unit → Lesson → Question`), so wiring the app to the API later is a
straight swap of `course_data.dart`.
