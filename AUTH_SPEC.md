# ኢትLingo (EtLingo) — Auth & User Management Spec

> Specification of authentication, authorization, and user management across the etLingo monorepo.
> Companion to `CODEBASE_SPEC.md`. Reflects code as implemented on `master`.

## 1. Overview — two auth planes

The system has **two independent identity planes** sharing one JWT secret but with different
token shapes, middleware, and lifecycles:

| | Admin plane | App (learner) plane |
| --- | --- | --- |
| Who | Content staff using the React console | Learners using the Flutter mobile app |
| Identity source | Local `admins` table (email + password) | Firebase Authentication (Google Sign-In) |
| Password storage | bcrypt, cost 12 | n/a (delegated to Firebase) |
| Token | JWT HS256 `{ sub, role }`, default 7d | JWT HS256 `{ sub, role: 'app_user' }`, fixed 30d |
| Middleware | `requireAuth` (`src/middleware/auth.js`) | `requireAppAuth` (`src/middleware/appAuth.js`) |
| Roles | `super`, `editor` (enum on `admins.role`) | single role `app_user` |
| Storage client-side | localStorage `etlingo_token` / `etlingo_admin` | none yet (Flutter has no HTTP layer) |

Both middlewares re-check the DB on every request, so deleting/banning an account takes
effect immediately even for outstanding tokens (no revocation list needed).

---

## 2. Admin plane

### 2.1 Data model (`admins`)

| Column | Type | Notes |
| --- | --- | --- |
| id | INT UNSIGNED PK | |
| name | STRING(120) | display name |
| email | STRING(190) UNIQUE | lowercased + trimmed on login/create |
| password_hash | STRING(255) | bcrypt cost 12; never serialized in responses |
| role | ENUM(`super`,`editor`) | default `editor`; seeded super = `admin@etlang.app / admin123` |

### 2.2 Endpoints (`src/controllers/auth.controller.js`)

| Method & path | Auth | Behavior |
| --- | --- | --- |
| `POST /api/v1/auth/login` | public (+rate limit) | Body `{ email, password }`. Case-insensitive email lookup; constant-ish failure (`401 invalid credentials`) for unknown user vs wrong password. Returns `{ token, ...admin }` (hash stripped). |
| `GET /api/v1/auth/me` | Bearer | Re-resolves admin from token `sub`; 401 if deleted. Returns admin row minus hash. Used by console to refresh session. |
| `POST /api/v1/auth/create-admin` | Bearer, **super only** | Body `{ name, email, password, role? }`. Min password 8 chars; 409 on duplicate email; defaults role `editor`. ⚠️ Returns a token **for the newly created admin** (swaps caller's session if stored blindly). |
| `POST /api/v1/auth/change-password` | Bearer | Body `{ currentPassword, newPassword }`. Verifies current password; min 8 chars; bcrypt(12). No other-session invalidation (stateless tokens stay valid). |

### 2.3 Login rate limiting

In-memory per-email limiter (`checkLoginRateLimit`):
* Max **5 failed-shape attempts per email per 15-minute window** → `429` with retry minutes.
* Entries pruned by a `setInterval` every 5 min.
* Scope caveats: keyed by email only (not IP), resets on server restart, does not work
  across multiple instances. Redis is available in-stack if this needs to be shared.

### 2.4 Authorization model

* `requireAuth` — verifies HS256 signature + expiry, loads admin from DB, sets `req.auth = { sub, role }`.
* `requireSuper` — exists in middleware but is **unused**; the super check is done inline
  inside `createAdmin` instead.
* All `/admin/*` routes require any signed-in admin; there is currently **no route-level
  distinction between `super` and `editor`** beyond admin creation. An editor can delete
  languages, ban users, and delete learners today.

### 2.5 Admin console contract (`admin/src`)

* `api/client.js` axios instance (`baseURL /api/v1`) attaches `Authorization: Bearer <etlingo_token>`.
* Response interceptor: on `401` → clears localStorage keys and hard-redirects to `/login`.
* `AuthContext` hydrates `admin` from localStorage on boot; no server-side session validation
  until the first API call returns 401.

---

## 3. App (learner) plane

### 3.1 Data model (`app_users`)

| Column | Type | Notes |
| --- | --- | --- |
| id | INT UNSIGNED PK | |
| firebase_uid | STRING(128) UNIQUE NULL | set on Google sign-in |
| device_id | STRING(64) UNIQUE NULL | reserved for guest/device flow (**not wired**) |
| email | STRING(190) UNIQUE NULL | synced from Firebase token |
| display_name | STRING(120) | defaults to Firebase name or email prefix or `'Learner'` |
| password_hash | STRING(255) NULL | reserved for email/password flow (**not wired**) |
| provider | ENUM(`guest`,`email`,`google`) | only `google` is produced today |
| status | ENUM(`active`,`banned`) | ban blocks new tokens AND existing ones (checked per request) |
| xp / hearts / streak | INT | gamification counters (hearts default 5) |
| last_active_date | DATEONLY | column exists, **never written** |

`updatedAt: false` — rows track `created_at` only. Cascades: `lesson_progress` and
personal notifications are deleted with the user.

### 3.2 Sign-in flow (`POST /api/v1/app/auth/google`)

```
Flutter app                      Backend                              Firebase
   │  GoogleSignIn → idToken         │                                    │
   ├──────── { idToken } ───────────▶│ verifyIdToken(idToken) ──────────▶│
   │                                 │◀── decoded { uid, email, name } ──┤
   │                                 │ findOrCreate AppUser(firebase_uid)
   │                                 │ 403 if status = banned            │
   │                                 │ sync email/display_name drift     │
   │◀──── { token, user } ───────────┤ issue session JWT                 │
```

Details:
* Requires Firebase Admin SDK initialized (`FIREBASE_KEY_PATH`); otherwise `400`.
* Verification failure → `401 Invalid or expired Firebase token`.
* New users start `provider='google'`, status `active`, xp 0 / hearts 5 / streak 0.
* Session JWT claims `{ sub: <AppUser.id>, role: 'app_user' }`, expiry **hard-coded 30d**
  (ignores `JWT_EXPIRES_IN`).
* Response body: `{ token, user: { id, email, displayName, status, provider, xp, hearts, streak } }`.

### 3.3 Session endpoints

| Method & path | Auth | Behavior |
| --- | --- | --- |
| `GET /api/v1/app/auth/profile` | Bearer app token | Serialized own profile. |
| `PUT /api/v1/app/auth/profile` | Bearer app token | Only `display_name` mutable: trimmed, non-empty, sliced to 120 chars. |
| `GET /api/v1/app/notifications` | Bearer app token | Personal + broadcast notifications. |
| `POST /api/v1/app/notifications/:id/read` | Bearer app token | Marks read. |

### 3.4 Middleware rules (`requireAppAuth`)

1. `Authorization: Bearer <jwt>` required → else 401.
2. Signature/expiry verified against shared `JWT_SECRET`.
3. Claim `role` must equal `'app_user'` — **admin tokens are rejected here**, and
   `requireAuth` implicitly rejects app tokens because their `sub` won't resolve to an admin.
4. User must still exist and must not be `status='banned'` (per-request DB hit).

---

## 4. User management (admin-side)

Admin endpoints over learner accounts (`src/controllers/appUsers.controller.js`),
all guarded by `requireAuth`:

| Method & path | Behavior |
| --- | --- |
| `GET /api/v1/admin/app-users` | List all learners, newest first. Filters: `?status=active\|banned`, `?q=<substring>` (LIKE on email/display_name). Each row augmented with `lessonsDone` (count of lesson_progress). ⚠️ No pagination — full table scan per call. |
| `PUT /api/v1/admin/app-users/:id` | Partial update of `display_name` (≤120), `status` (`active`\|`banned`, else 400), `xp`, `hearts` (clamped ≥ 0). Returns row incl. `lessonsDone`. |
| `DELETE /api/v1/admin/app-users/:id` | Hard delete; cascades progress + notifications. 204. No confirmation/super-role gate. |

Ban semantics: banned users fail `requireAppAuth` with 401 on every request, so bans apply
instantly without token revocation. Unban restores access with the same session token.

---

## 5. Security posture & known gaps

Ranked roughly by urgency:

1. **Firebase service-account key is untracked-but-committable.**
   `backend/etlingo-firebase-adminsdk-fbsvc-*.json` sits in the repo root of backend and
   `.gitignore` only covers `node_modules/` and `.env`. Anyone committing blindly leaks the
   key (full Auth + FCM admin on the project). → Add `*.json` key pattern to `.gitignore`,
   move file outside the repo or load via env/secret store.
2. **JWT secret fallback** `'change_me_in_production'` in both middlewares — a missing env
   var silently degrades to a publicly-known secret. → Fail fast at boot if unset.
3. **No logout / revocation.** Tokens are stateless; a leaked learner token lives up to 30d,
   admin token 7d. Mitigation: per-request DB checks catch deletion/ban only. Acceptable for
   MVP; short TTLs + refresh would be the next step.
4. **Rate limiter is in-memory and per-instance** (see §2.3); fine for single-node deploys.
5. **Editors have full destructive power** — no `requireSuper` gating on deletes, bans, or
   notifications. The middleware already exists; wiring it onto destructive routes is cheap.
6. **No pagination** on `GET /admin/app-users` (and content CRUD lists generally).
7. `createAdmin` response swaps the caller's session token if naively stored (console doesn't
   call it yet, so latent).
8. `last_active_date` / streak columns never updated — streak logic is client-side mock only.

## 6. Reserved-but-unimplemented paths

The schema anticipates two more sign-in modes that have **no endpoints yet**:

| Mode | Schema support | Needed work |
| --- | --- | --- |
| Guest / device | `device_id`, `provider:'guest'` | `POST /app/auth/guest { deviceId }` → findOrCreate + token; merge policy when guest later upgrades |
| Email + password | `password_hash`, `provider:'email'` | register/login/forgot-password endpoints, email verification strategy (or delegate entirely to Firebase Email/Password and reuse the Google flow shape) |

Recommended direction: keep Firebase as the sole credential authority for learners
(enable its Email/Password provider too), so the backend keeps verifying ID tokens through
one code path (`googleSignIn` generalizes to `firebaseSignIn`) regardless of provider.

## 7. Open decisions

1. Guest play: allow offline-first guests that sync later, or require sign-in before lessons?
2. Should banning also delete FCM tokens / block notifications delivery?
3. Do admins need audit logging (who banned/deleted whom)?
4. Token TTL policy for learners (30d vs shorter + Firebase silent re-auth on app start)?

---
*Related files: `backend/src/middleware/auth.js`, `backend/src/middleware/appAuth.js`,
`backend/src/controllers/auth.controller.js`, `backend/src/controllers/appAuth.controller.js`,
`backend/src/controllers/appUsers.controller.js`, `backend/src/config/firebase.js`,
`backend/db/schema.sql`.*
