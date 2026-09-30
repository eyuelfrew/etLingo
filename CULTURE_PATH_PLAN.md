# Culture Path — Implementation Plan (etLingo)

> Goal: pair **language learning** with **Ethiopian culture** so etLingo is not a generic Duolingo clone.
> This document is the shared build plan. Check items off as we ship them together.

**Status:** Phase 1–4 **shipped** · polish / content packs ongoing · **Owner:** product + eng

---

## 1. Product thesis

| Track | Purpose | Example |
| --- | --- | --- |
| **Language Path** | Speak/read the target language | ሰላም · greetings · quizzes |
| **Culture Path** | Live the culture behind the language | Timkat · buna ceremony · proverbs |

**One loop, not two apps:**
- Shared **XP / hearts / streak / badges**
- Same **base language** (explain culture in EN / so / am…)
- Same **admin** content pipeline (units → cards → media on S3)
- Learners switch tracks: **Language | Culture** on Learn

---

## 2. Scope

### In this roadmap
- Culture Path per **course language**
- Chapters + cards (text / fact / proverb / steps / vocab / calendar / media)
- Proverb of the Day
- Ethiopian calendar + holiday hooks
- Recipe / coffee ceremony guides
- Lightweight chapter discussion (likes/comments)
- Offline culture cache + low-bandwidth text-only

### Later
- Fidel trainer & handwriting
- Music & lyrics (public-domain only)
- Language exchange / native matching
- User-submitted stories (moderation)
- AR/photo filters, diaspora leaderboards
- TTS fallback

---

## 3. Content model

```
Language (course: am | om | ti | so)
  └─ Culture track
        └─ CultureUnit (chapter)
              └─ CultureCard (slideshow card)
```

**Tables (shipped):** `culture_units`, `culture_cards`, `culture_progress`

---

## 4. Phased delivery

### Phase 0 — Decisions
- [x] Track switch on Learn
- [x] Card XP = 5 default
- [x] Coffee ceremony seed
- [x] Per language · cards only first

### Phase 1 — Admin + API skeleton
- [x] Tables + migrate
- [x] Admin CRUD Culture page
- [x] Multi-base `content` JSON
- [x] Media attach (S3)
- [x] `GET /app/culture/:code` bootstrap

### Phase 2 — Mobile Culture Path
- [x] Track switch UI
- [x] Chapter list
- [x] Card reader + vocab + audio + base language
- [x] Complete card → XP + `culture_progress`
- [x] Pull-to-refresh + offline cache

### Phase 3 — Signature content + retention
- [x] Proverb of the Day (API + home card)
- [x] Ethiopian calendar widget + holiday highlight
- [x] Recipe / coffee **steps** cards with vocab
- [x] Holiday XP events (Timkat / Meskel)
- [x] Culture unit likes/comments (reuse engagement pattern)

### Phase 4 — Stretch
- [x] Fidel trainer
- [x] Music/lyrics (public-domain only)
- [x] Community stories + moderation
- [x] Language exchange
- [x] AR share cards

---

## 5. Working agreement
1. One phase end-to-end before expanding.
2. JSON `content` for i18n over extra tables.
3. Media via S3 + `/api/v1/media` proxy.
4. Update checkboxes when a step ships.

---

## 6. Shipped (Phase 1–4)

| Item | Status |
| --- | --- |
| culture tables + progress | Done |
| Admin Culture Path + Community moderation | Done |
| App bootstrap + card complete + proverb + calendar API | Done |
| Flutter Language \\| Culture + card reader + XP | Done |
| Coffee seed (4 cards) + Timkat / Proverbs / Folk packs | Done |
| Base-language card body + steps + vocab | Done |
| Offline culture cache + download chip | Done |
| Holiday XP (2× on feast windows) | Done |
| Culture unit likes/comments | Done |
| Fidel trainer + exchange waitlist + share card | Done |

**Try it:** Learn → **Culture** · home Proverb + calendar · holiday challenge · Fidel · Community (admin).

**Note:** Phase 4 social features are v1 (waitlist matching, moderated stories, text share card). Full AR filters / partner chat / handwriting still later.

---

## 7. Scripts & alphabets (scripture / writing systems)

Admin-managed writing systems **per language** (Ge'ez fidel, Latin/Qubee, Arabic, Osmanya).

| Piece | Status |
| --- | --- |
| `scripts` + `script_letters` + `language_scripts` | Done |
| **Language-first** admin flow (language → script → letters) | Done |
| `POST /admin/languages/:id/scripts` (auto primary) | Done |
| Languages row → **Script** shortcut | Done |
| Fidel trainer uses admin letters (offline fallback) | Done |
| **Letter pronunciation audio** (admin upload + listen-first trainer) | Done |
| **Full fidel families** (7 orders ሀ…ሆ + labiovelar 8th) | Done |
| Family browser + family-vs-form practice | Done |
| **Drag-drop / ▲▼ reorder** (families + vowel forms) | Done |

**Seed:** `npm run db:seed-scripts` — ethi **271 letters / 34 families** (7 orders + wa), latn, arab, osma + language maps.  
`node scripts/seed-fidel-full.mjs` reseeds the full Ge'ez chart.

**Audio:** each letter (including ሁ ሂ ሃ…) can have pronunciation audio. Admin → family → edit form → **Pronunciation audio**.

---

## 8. Topic packs (content-based learning)

Theme word lists (Animals, Food, Colors…) with audio + meaning per language.

| Piece | Status |
| --- | --- |
| `topic_categories` + `topic_words` | Done |
| Admin **Topic packs** page (themes + words + audio) | Done |
| App **Topic packs** screen + word list + quiz | Done |
| Offline cache | Done |
| Seed: animals (16), food (12), colors (8) | Done |

---

## 9. Ethiopian calendar (interactive)

| Piece | Status |
| --- | --- |
| Accurate JDN conversion (Eth ↔ Gregorian) | Done |
| Month grid + weekday headers (እሁድ…ቅዳሜ) | Done |
| Holidays on Ethiopian dates (Enkutatash, Meskel, Genna, Timkat, Adwa…) | Done |
| Dual date (Eth + Gregorian) + upcoming holidays | Done |
| Open from home / Culture calendar chip | Done |
| **Bottom nav Script tab** (learner alphabet home) | Done |

---

## 12. Learner API gaps closed

| Piece | Status |
| --- | --- |
| Topic word “known” + XP (`topic_word_progress`) | Done |
| `GET /app/topics/progress` · mark/unmark known | Done |
| Phrasebook screen (`/app/:code/phrases`) | Done |
| Known flags on topic packs | Done |

---

## 13. Pay-per-chapter (unit purchases)

**Model:** one-time Chapa payment unlocks a **chapter/unit**. No subscription required.

| Piece | Status |
| --- | --- |
| Unit `price_cents` (0 = free, >0 = paid) | Done |
| Admin **Price (cents)** on unit | Done |
| Chapa checkout for `unit:<id>` | Done |
| Server verify → permanent unlock | Done |
| App lock + **Unlock chapter** dialog | Done |
| `purchasedUnitIds` on bootstrap | Done |
| Legacy subscription packages | Kept in admin (optional) |

### Chapa (Ethiopia) — test mode wired
| Piece | Status |
| --- | --- |
| Create hosted checkout (`/v2/payments/hosted`) | Done |
| Server **verify** (`/v2/payments/:ref/verify`) | Done |
| Grant subscription after verify | Done |
| App opens `paymentUrl` | Done |
| **Payment return auto-verify screen** | Done |
| **Admin cancel user subscription** (Users page) | Done |
| Keys | `backend/.env` → `CHAPA_SECRET_KEY` / `CHAPA_PUBLIC_KEY` (gitignored) |

---

## 10. In-house ads (not AdMob)

Admin-managed promo slots with placement + tap action + CTR tracking.

| Piece | Status |
| --- | --- |
| `ads` table (position, action, schedule, impressions/clicks) | Done |
| Admin **In-app ads** (CRUD, image, CTA, position, dates) | Done |
| Slots: home_top · home_mid · culture_top · after_topics · profile | Done |
| Tap actions: URL / app screen / topic / info | Done |
| Click + impression tracking (CTR in admin) | Done |

---

## 11. Security hardening

See `SECURITY.md` for the full checklist. Highlights: JWT `aud`/`iss` + `token_version`, auth/write/upload rate limits, comment sanitization, production secret & password policy, HSTS, generic 500s.

