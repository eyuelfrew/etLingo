# ኢትLingo (EtLingo) — Monorepo

An ecosystem for learning Ethiopian languages.

| Folder | Stack | Purpose |
| --- | --- | --- |
| `etlingo/` | Flutter · Dart | Mobile learner app (Duolingo-style) |
| `backend/` | Node.js · Express · MySQL · Redis | Content & admin API |
| `admin/` | React · Vite · Tailwind CSS | Admin console for managing courses |

## Quick start

```bash
# 1. Backend (needs MySQL running; Redis optional)
cd backend
npm install
npm run db:init     # creates schema + seeds admin + starter languages
npm run dev         # http://localhost:5050

# 2. Admin console
cd ../admin
npm install
npm run dev         # http://localhost:5173 (proxies /api to :5050)

# 3. Mobile app
cd ../etlingo
flutter pub get
flutter run
```

## Default admin login

`admin@etlang.app` / `admin123` — change in production via `.env`.
