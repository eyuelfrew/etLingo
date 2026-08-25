# ኢትLingo (EtLingo) — Codebase Specification

> A specification of the etLingo monorepo: an ecosystem for learning Ethiopian languages.
> Root: `D:\etlingo` · No VCS repo detected (no `.git` at root).

## 1. System overview

| Folder | Stack | Purpose |
| --- | --- | --- |
| `etlingo/` | Flutter · Dart | Mobile learner app (Duolingo-style) |
| `backend/` | Node.js · Express · MySQL · Redis | Content & admin API |
| `admin/` | React · Vite · Tailwind CSS | Admin console for managing courses |

The mobile app reads course content (languages → units → lessons → questions) from the
backend API. Admins author that content through the admin console. The backend currently
serves the API; the Flutter app still uses a hard-coded `course_data.dart` but the data shape
is mirrored end‑to‑end (see §8) so wiring the app to the API is described as a straight swap.

---

## 2. Repository layout

```
D:\etlingo\
├── README.md                  # Monorepo overview + quick start
├── admin/                     # React admin console (Vite)
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js
│   ├── dist/                  # Built output (static assets)
│   └── src/
│       ├── main.jsx, App.jsx, index.css
│       ├── api/client.js
│       ├── components/Layout.jsx
│       ├── context/AuthContext.jsx
│       └── pages/  (Login, Dashboard, Languages, Lessons, Phrases)
├── backend/                   # Node/Express API
│   ├── package.json, .env.example, nodemon.json, README.md
│   ├── db/schema.sql
│   ├── scripts/db-init.js
│   └── src/
│       ├── server.js
│       ├── config/  (db.js, redis.js, status.js)
│       ├── controllers/ (auth.controller.js, content.controller.js)
│       ├── middleware/auth.js
│       ├── models/ (index.js + 8 model files)
│       ├── routes/index.js
│       └── utils/http.js
└── etlingo/                   # Flutter mobile app
    ├── pubspec.yaml, README.md, .metadata
    ├── test/widget_test.dart
    ├── lib/
    │   ├── main.dart, app.dart
    │   ├── state/app_state.dart
    │   ├── data/ (models.dart, course_data.dart)
    │   ├── core/ (theme/app_theme.dart, widgets/…)
    │   └── features/ (splash/, onboarding/, home/, lesson/)
    ├── android/, ios/, linux/, macos/, web/, windows/   # Flutter platform shells
    └── build/, .dart_tool/
```
## 3. Domain data model

The core domain is a strict tree, mirrored across the DB schema, the Sequelize models,
the bootstrap API payload, and the Flutter `models.dart`.

    Language (code, name, native_name, colors, hello word …)
      └─ Unit (title, subtitle, colors, icon)
           └─ Lesson (title, is_boss, xp_reward)
                 └─ Question (kind = mcq | fill | match)

Plus a flat `Phrase` list per language, and learner accounts/progress.

### Question kinds
| kind | Data used | App view |
| --- | --- | --- |
| `mcq` | prompt, sub_prompt, hint, options[], answer_index | McqView (2-col grid) |
| `fill` | prompt, sub_prompt (with `___` blank), options[], answer_index | FillView (tap word into blank) |
| `match` | prompt, match_left[], match_right[] (same length) | MatchView (left tap then right tap) |

---

## 4. Backend — spec

Node.js (ES modules, `"type": "module"`) + Express 5 + Sequelize 6 + MySQL 8
(mysql2) + optional Redis (ioredis). Also: bcryptjs, jsonwebtoken, cors, dotenv, nodemon (dev).

### 4.1 Service & config
* Port `5050`, health at `/api/health`.
* All business routes mounted at `/api/v1` (`src/routes/index.js`).
* `src/config/db.js` — `createDatabase()` creates the DB if missing; a global
  `sequelize` instance (dialect mysql, underscored, `created_at` only).
* `src/config/redis.js` — Redis is optional (enabled only if `REDIS_URL` set).
  Exposes `redisEnabled`, `pingRedis()`, `cacheGet(key)`, `cacheSet(key, value, ttl)`.
* `src/config/status.js` — tracks MySQL/Redis liveness; `checkStatus()`,
  `getMysqlStatus()`, `getRedisStatus()`; checked at boot and every 30 s.
* `src/utils/http.js` — `HttpError`, `badRequest/unauthorized/notFound`, `asyncHandler`,
  `errorHandler` (500s are logged).

### 4.2 Auth (`src/middleware/auth.js`, `controllers/auth.controller.js`)
* Password hashing: bcrypt (cost 12). Admin tokens: `jsonwebtoken` HS256.
* `signToken(admin)` → claims `{ sub, name, email, role }`, expiry `JWT_EXPIRES_IN` (default `7d`).
* `requireAuth` middleware reads `Authorization: Bearer <token>` and verifies; throws 401 otherwise.
* Login returns `{ token, ...admin }` (JSON body `{ email, password }`).

### 4.3 Database schema (`db/schema.sql` + Sequelize models)
All tables use `utf8mb4`. `db/schema.sql` is the canonical DDL; `scripts/db-init.js`
instead calls `sequelize.sync()` to create tables and then seeds data.

| Table | Key columns | Notes |
| --- | --- | --- |
| `admins` | id, name, email (unique), password_hash, role enum(`super`,`editor`) | bcrypt hash |
| `languages` | id, code (unique), name, native_name, script_preview, speakers, region, color_hex, dark_hex, hello_target, hello_meaning, icon, sort_order, is_active | per-course branding |
| `units` | id, language_id FK, title, subtitle, color_hex, dark_hex, icon, sort_order | cascade delete |
| `lessons` | id, unit_id FK, title, is_boss (bool), xp_reward, sort_order | boss = review/flag lesson |
| `questions` | id, lesson_id FK, kind enum(`mcq`,`fill`,`match`), prompt, sub_prompt, hint, options JSON, answer_index, match_left JSON, match_right JSON, sort_order | JSON cols for variable shape |
| `phrases` | id, language_id FK, target, translit, meaning, category, sort_order | phrasebook rows |
| `app_users` | id, device_id/email (unique nullable), display_name, password_hash, provider enum(`guest`,`email`), xp, hearts, streak, last_active_date | learner accounts |
| `lesson_progress` | id, app_user_id, lesson_id, mistakes, xp_earned, completed_at; unique (app_user_id, lesson_id) | completion records |

Associations (`src/models/index.js`): Language hasMany Unit/Phrase; Unit hasMany Lesson;
Lesson hasMany Question and LessonProgress; AppUser hasMany LessonProgress. All children
use `onDelete: CASCADE`.

### 4.4 Controllers (`src/controllers/`)
* `content.controller.js` — a generic CRUD factory `makeCrud(Model, fields, jsonFields)`
  producing `list / getOne / create / update / remove` for every resource. `dashboardStats()`
  returns row counts `{ languages, units, lessons, phrases, questions }`.
* `auth.controller.js` — `login`, `me`, `createAdmin` (bcrypt + JWT).

### 4.5 REST API (all under `/api/v1`)
Public (no auth):
* `GET /health` `GET /status` `POST /status/refresh` — liveness/status of MySQL + Redis.
* `GET /app/bootstrap/:code` — returns `{ language, units, lessons, questions, phrases }`
  as one nested camelCase tree (`colorHex`, `helloTarget`, `isBoss`, `answerIndex`, …).
  This is the payload shape a wired Flutter app consumes.
* `GET /app/:code/phrases` — flat phrase list for a language code.
* `POST /auth/login` — `{ email, password }` → `{ token, ...admin }`.

Admin (requires Bearer JWT):
* `GET /auth/me` `POST /auth/create-admin`
* `GET /admin/stats`
* Languages / Units / Lessons / Questions / Phrases:
  `GET :list`, `GET /:id`, `POST`, `PUT /:id`, `DELETE /:id`
  (list supports `?field=value` filtering; ordered by sort_order then id).

> Note: `questions` CRUD accepts `options`, `match_left`, `match_right` as JSON fields.

### 4.6 Environment (`backend/.env.example`)
`PORT=5050 · DB_HOST=localhost · DB_PORT=3306 · DB_USER=root · DB_PASS= · DB_NAME=etlingo · REDIS_URL=redis://localhost:6379 · JWT_SECRET · JWT_EXPIRES_IN=7d`

### 4.7 Seeding (`scripts/db-init.js`, `npm run db:init`)
Creates DB + tables, upserts super admin `admin@etlang.app / admin123`, seeds four starter
languages with branding: Amharic (`am`), Afaan Oromo (`om`), Tigrinya (`ti`), Somali (`so`).

### 4.8 Known inconsistency
`schema.sql` creates a database named `etlang` and uses `USE etlang;`, while
`src/config/db.js` and `.env.example` default to database name `etlingo`. If you rely on
`schema.sql` to bootstrap, table creation lands in a different database than the Sequelize
instance connects to. Running `npm run db:init` (which calls `createDatabase()` with the
`.env` name) is the intended path.

## 5. Admin console — spec

React 19 + react-router-dom 7 + axios + Tailwind CSS 4, served by Vite 7.

### 5.1 Tooling
* `vite.config.js` — port `5173`; dev proxy forwards `/api` → `http://localhost:5050`
  (so the console talks to the backend with the same relative base).
* `src/api/client.js` — axios instance with `baseURL /api/v1`; a request interceptor adds
  `Authorization: Bearer <etlingo_token>` from localStorage; a response interceptor clears
  auth and redirects to `/login` on 401.
* `src/index.css` — imports Tailwind, defines the Ethio palette CSS variables.

### 5.2 Auth (`src/context/AuthContext.jsx`)
Context `{ admin, login, logout }`. Session persists in localStorage keys
`etlingo_token` and `etlingo_admin`. On load, `admin` is hydrated from localStorage.

### 5.3 Routing (`src/App.jsx`)
* `/login` → `Login`.
* `/` (wrapped in `Protected`) → `Layout` with nested routes:
  - index → Dashboard
  - `/languages` → Languages
  - `/lessons` → Lessons
  - `/phrases` → Phrases
* `*` → redirect to `/`.
`Protected` redirects to `/login` when no admin.

### 5.4 Pages
| Route | Page | Behavior |
| --- | --- | --- |
| `/login` | Login | Email/password form, animated Ethio background, calls `login()`; shows an error card |
| `/` | Dashboard | Calls `/admin/stats`; renders count cards (languages, units, lessons, questions, phrases) + a "getting started" list |
| `/languages` | Languages | Full CRUD table + modal form (code, names, colors, greeting, sort order, active flag) |
| `/lessons` | Lessons | Reads languages, then `GET /app/bootstrap/:code`; renders the course tree (units → lessons w/ question counts & XP). Notes "full lesson editor ships with your spec" |
| `/phrases` | Phrases | Filter by language; inline add/edit/delete form for phrase rows (target, translit, meaning, category) |

### 5.5 Layout (`src/components/Layout.jsx`)
Sidebar nav (Dashboard ▦ / Languages 🗣 / Lessons 📚 / Phrasebook 💬) + signed-in admin
name + sign-out. Main content wraps `<Outlet />`.

## 6. Flutter mobile app — spec

Flutter (Dart SDK `^3.10.4`), package `etlingo`, version `1.0.0+1`. Material 3,
cupertino_icons, flutter_lints, flutter_test (dev).

### 6.1 Entry & routing
* `lib/main.dart` — ensures Flutter bindings, sets system UI overlay, runs
  `EtLangApp(state: AppState())`.
* `lib/app.dart` — `EtLangApp` builds a `MaterialApp` (theme `buildEtTheme()`) with routes:
  | Route | Screen |
  | --- | --- |
  | `/` | `SplashScreen` |
  | `/pick` | `LanguagePickerScreen` |
  | `/home` | `HomeShell` |

### 6.2 Client state (`lib/state/app_state.dart`)
`AppState extends ChangeNotifier` — the single source of learner truth:
* Fields: `language` (defaults to Amharic), `completedLessons` (Set of lesson ids),
  `xp`, `xpToday`, `hearts` (default 5), `streak` (hard-coded 6), `onboarded`, `dailyGoal` (50).
* Derived: `goalProgress` (`xpToday / dailyGoal`), `isLessonComplete`, `completedInUnit`,
  `nextLesson`, `unitOf`, `languageUnit`/`totalLessons`.
* Mutators (each calls `notifyListeners`): `chooseLanguage`, `loseHeart`, `refillHearts`,
  `completeLesson` (adds id, grants 10 XP, +5 bonus when perfect), `lessonReward`
  (15 perfect / 10 otherwise), `resetProgress`.

### 6.3 Data model (`lib/data/models.dart`)
`QuestionKind { mcq, match, fill }`; `WordOption(label, emoji?)`; classes
`Question` (with named factory constructors `.mcq`, `.fill`, `.match`), `Lesson` (id, title,
isBoss, questions), `Unit` (title, subtitle, color, dark, icon, lessons), `Phrase` (target,
translit, meaning, category), `Language` (id, name, nativeName, scriptPreview, speakers,
region, color, dark, icon, comingSoon, helloTarget, helloMeaning, units, phrases).

### 6.4 Content (`lib/data/course_data.dart`)
Hard-coded seed courses (mirrors the backend's data shape):
`amharic`, `oromo`, `tigrinya`, `somali` + `languageById()` fallback to Amharic.
`afarComingSoon` / `wolayttaComingSoon` stubs exist but are not in the `languages` list.
Amharic has a 3-lesson Unit 1 (First words / How are you? / Unit 1 review [boss]); others
have a single greetings unit.

### 6.5 Theme & shared widgets (`lib/core/`)
* `theme/app_theme.dart` — `EtColors` (Ethio palette: green/yellow/red/blue + ink/paper/card/
  line/muted/locked), `EtShadows` (lift + soft), and `buildEtTheme()` (Material 3, paper
  scaffold, custom app bar).
* `widgets/et_button.dart` — `EtButton` with palette styles (`primary/danger/info/gold/neutral`),
  press animation, optional icon, expanded/disabled states.
* `widgets/tibeb_band.dart` — a decorative Ethio‑style zigzag/diamond painter band.
* `widgets/confetti.dart` — `ConfettiRain`, custom-painted celebratory particle overlay.

### 6.6 Screens (by feature)
| Feature | File | Purpose |
| --- | --- | --- |
| splash | `splash_screen.dart` | Animated logo/emblem intro; auto-navigates to `/pick` or `/home` |
| onboarding | `language_picker_screen.dart` | "Which language do you want to learn first?" list → `chooseLanguage` + `/home` |
| home | `home_shell.dart` | 4-tab bottom nav (Learn / Words / Rank / You) hosting the 4 screens below |
| home | `learn_path_screen.dart` | Course header (native name, XP/streak/hearts chips, daily-goal bar), Word of the Day, zig-zag lesson path with START pulse on the current unlocked node |
| home | `phrasebook_screen.dart` | Searchable, category-grouped phrasebook list |
| home | `leaderboard_screen.dart` | MOCK league ("Gold League") + real user XP row |
| home | `profile_screen.dart` | Avatar, goal ring (custom painter), stat cards, achievements, reset-progress with confirm |
| lesson | `lesson_screen.dart` | Drives the quiz flow: progress bar, hearts counter, question type view, Check/Continue, exit-confirm dialog, out-of-hearts refill |
| lesson | `question_views.dart` | `McqView` (2-col grid), `FillView` (tap word into `___` blank), `MatchView` (tap left then right, shuffle, wrong-pair flash) |
| lesson | `lesson_result_screen.dart` | Post-lesson celebratory screen: confetti, XP / streak / hearts cards, "Keep going!" |

### 6.7 Quiz & gamification rules (from code)
* Each wrong mcq/fill loses 1 heart; out of hearts shows a free-refill dialog.
* Match wrong pairs increment mistakes + lose a heart per pair; completing all pairs counts as correct.
* Completing a lesson adds the id, grants 10 XP (+5 if zero mistakes), shows result screen.
* The result screen's XP card reads `lessonReward` (15 flawless / 10 else) and confetti "Flawless!" if mistakes == 0.

## 7. Tests

`etlingo/test/widget_test.dart` (flutter_test):
* Course data well-formed — every language/unit/lesson/question has non-empty content;
  mcq/fill `answerIndex < options.length`; match `matchLeft.length == matchRight.length`.
* App boots to splash then language picker (after ~3 s).
* Full lesson flow — drives MCQs, a 3-pair match, a fill, and asserts hearts stay 5 (perfect
  run) with XP increased and lesson marked complete.

The backend and admin console ship without automated tests; validation is manual via
`npm run db:init` / `npm run dev` and the admin UI.

---

## 8. Cross-app contracts & gaps

* Data shape is aligned: backend `bootstrap/:code` already emits `camelCase` keys
  (`colorHex`, `darkHex`, `helloTarget`, `isBoss`, `xpReward`, `answerIndex`, `matchLeft`,
  `matchRight`, `subPrompt`) that match `course_data.dart`/`models.dart`. Wiring the Flutter
  app to the API is intended to be a swap of the hard-coded data source.
* The Flutter app is currently **offline** — state and content live in-memory
  (`AppState`, `course_data.dart`); there is no HTTP client, persistence, auth, or
  user/lesson-progress sync yet. The backend tables `app_users` / `lesson_progress` exist
  but are unused by any app.
* Leaderboard is mock data; profile streak is hard-coded; daily-goal resets are not persisted.
* Admin **Lessons** page is read-only (course-tree preview). A full lesson editor
  (units/lessons/questions authoring) is called out in UI copy as "ships with your spec".
* Backend DB-name mismatch `etlang` (schema.sql) vs `etlingo` (config/.env), noted in §4.8.

---

## Appendix A — Quick start (from README)

1. Backend: `cd backend` → `npm install` → `npm run db:init` → `npm run dev` (`:5050`).
2. Admin: `cd ../admin` → `npm install` → `npm run dev` (`:5173`, proxies `/api` → `:5050`).
3. App: `cd ../etlingo` → `flutter pub get` → `flutter run`.
4. Default admin login: `admin@etlang.app` / `admin123`.
