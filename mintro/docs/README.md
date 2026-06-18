# Mintro

Mintro is a gamified personal-finance and economics learning app. It teaches money concepts through short, Duolingo-style lessons while helping users build real savings goals — combining streaks, XP, coins, quests, leagues, and achievements with an actual savings tracker, so progress in the app maps to progress with money.

This document covers the project as built across Parts A–E of this build: system architecture, database schema, backend API, Flutter app, and the animation layer. It does not claim feature parity with every idea in the original product brief (15 leagues, 100+ achievements, social/friends, premium subscriptions, push notifications for every event type, etc.) — those are listed under **Future Improvements** with notes on what's already scaffolded to support them.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Folder Structure](#folder-structure)
- [Architecture](#architecture)
- [Installation](#installation)
- [Running the Backend](#running-the-backend)
- [Running the Frontend](#running-the-frontend)
- [Connecting Supabase](#connecting-supabase)
- [Environment Variables](#environment-variables)
- [Testing](#testing)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)
- [Scaling](#scaling)
- [Security Notes](#security-notes)
- [Cost Estimates](#cost-estimates)
- [Future Improvements](#future-improvements)

---

## Project Overview

| | |
|---|---|
| **Frontend** | Flutter (iOS, Android) — Riverpod, go_router-ready, repository pattern |
| **Backend** | Node.js 20 + Fastify + TypeScript |
| **Database** | Supabase (PostgreSQL + Auth + Realtime + Storage) |
| **Push** | Firebase Cloud Messaging |
| **Status** | Core gamification loop (lessons → XP/coins/streak/quests/leagues) is implemented end-to-end. Quiz UI, friends, subscriptions, and the full 100-achievement catalog are not. |

The split between Supabase and the Node API is deliberate: anything that's pure reference data or "my own profile" is read directly from Supabase by the Flutter client under Row Level Security. Anything that mutates XP, coins, streaks, or quest progress goes through the Node API, which holds the Supabase **service role** key and is the only thing allowed to call the privileged `award_xp_and_coins` / `update_streak` Postgres functions. This means a modified or jailbroken client cannot grant itself XP — RLS blocks direct writes to those columns, full stop.

---

## Features

### Implemented (Parts A–E)
- Email/password auth via Supabase Auth, with an `AuthGate` that reactively swaps between login and the main app on session change.
- Home dashboard: weekly streak dots (animated), daily XP goal progress bar, today's lesson list.
- Skill Tree: learning paths with per-path progress, a vertical skill-map node view.
- Quests: daily/weekly/monthly quest templates, per-user progress tracking, a featured quest card, claimable rewards.
- Savings goals: create a goal, contribute toward it, automatic milestone detection (25/50/75/100%) with bonus XP/coin payouts.
- Leagues: 7 tiers (Copper → Master), weekly automatic promotion/demotion via a cron job, leaderboard snapshots for fast reads.
- Profile: level/XP ring, stat tiles, primary goal ring chart, achievement grid.
- Animations: confetti, level-up modal, staggered reward chips, animated streak dots, custom page transitions — all gated behind a single `animationsEnabled` setting.
- Notifications scaffold: FCM send wrapper + `notifications_log` table + daily/weekly cron jobs that call it (streak-break warning, "you haven't hit your goal yet" reminder, league promotion/demotion).

### Scaffolded but not fully built
- **Quiz UI**: the scoring engine (multiple choice, true/false, match pairs, drag/drop, scenario) is implemented server-side in `lessonService.ts` and the `Lesson`/`QuizQuestion` models exist client-side, but there's no quiz-taking screen yet — `_startLesson` in the Home screen currently submits an empty answer set as a placeholder so the reward/animation pipeline could be demonstrated against a real endpoint.
- **Achievements**: the table, RLS, and display grid exist; the job that actually evaluates and awards achievements (e.g. "30-day streak") is not built. `user_achievements` rows currently have to be inserted manually or via the seed data.
- **Friends/social**: `friendships` table and RLS policies exist; no UI.
- **Premium subscription**: not implemented — no payment provider integration, no `is_premium` enforcement beyond the column existing on `learning_paths`/`lessons`.

### Not started
- Onboarding flow, avatar customization, store/cosmetics, dark mode, in-app notification center screen (the log exists, the screen doesn't), referral system.

---

## Folder Structure

```
mintro/
├── apps/
│   └── flutter_app/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── config/            # build-time config (--dart-define)
│       │   ├── theme/             # colors, text styles, ThemeData
│       │   ├── models/            # Profile, Lesson, Quest, Goal, Leaderboard, Achievement
│       │   ├── services/          # SupabaseService, ApiClient
│       │   ├── repositories/      # data access — direct Supabase or API-backed
│       │   ├── providers/         # Riverpod state
│       │   ├── animations/        # confetti, reward chips, overlays, transitions
│       │   ├── routes/            # AuthGate, RootShell
│       │   ├── widgets/           # MintroCard, MintroProgressBar, etc.
│       │   └── screens/           # one folder per feature area
│       ├── pubspec.yaml
│       └── analysis_options.yaml
├── services/
│   └── api/
│       ├── src/
│       │   ├── server.ts
│       │   ├── config/            # env loader, Supabase admin client
│       │   ├── middleware/        # auth (JWT verify), error handler
│       │   ├── validators/        # Zod schemas
│       │   ├── repositories/      # Supabase queries
│       │   ├── services/          # business logic (gamification, lessons, quests, goals)
│       │   ├── controllers/       # HTTP handlers
│       │   ├── routes/            # route registration
│       │   ├── jobs/              # cron: daily reset, weekly league rotation
│       │   └── notifications/     # FCM push wrapper
│       ├── package.json
│       └── .env.example
├── supabase/
│   └── migrations/
│       ├── 0001_init.sql          # core schema, RLS, functions, triggers
│       └── 0002_notifications.sql # FCM token, prefs, notifications_log
└── docs/
    ├── README.md                  # this file
    └── TUTORIAL.md
```

---

## Architecture

```
Flutter App ──────► Supabase (direct reads, RLS-protected)
     │                  - learning_paths, lessons, leagues, quests,
     │                    achievements, leaderboard_snapshots (public read)
     │                  - profiles, goals, user_lessons (own-row read)
     │
     └────────────► Node API (Fastify) ──────► Supabase (service role)
                          - verifies Supabase JWT on every request
                          - scores quizzes server-side
                          - calls award_xp_and_coins / update_streak
                            (SECURITY DEFINER Postgres functions)
                          - evaluates quest progress
                          - cron: daily streak-break check, weekly
                            league rotation + leaderboard snapshot
```

See `apps/flutter_app/lib/repositories/` for which repositories hit Supabase directly versus the API — as a rule, anything that changes XP/coins/streak/quest state is API-backed; everything else is a direct Supabase read.

---

## Installation

### Prerequisites

| Tool | Version | Check |
|---|---|---|
| Flutter SDK | ≥ 3.4.0 | `flutter --version` |
| Node.js | ≥ 20 | `node --version` |
| npm | bundled with Node | `npm --version` |
| Git | any recent | `git --version` |
| Supabase CLI (optional, for local dev) | latest | `supabase --version` |

A Supabase account (free tier is enough to start) is required — see [Connecting Supabase](#connecting-supabase).

### Clone and install

```bash
git clone <your-repo-url> mintro
cd mintro

# Backend
cd services/api
npm install
cd ../..

# Frontend
cd apps/flutter_app
flutter pub get
cd ../..
```

---

## Running the Backend

```bash
cd services/api
cp .env.example .env
# edit .env with your Supabase project's URL, service role key, and JWT secret
npm run dev
```

This starts the Fastify server on `http://localhost:3000` with hot reload (`tsx watch`). Verify it's up:

```bash
curl http://localhost:3000/health
# {"status":"ok","timestamp":"..."}
```

Cron jobs (daily reset, weekly league rotation) only run when `NODE_ENV=production` — in development they're skipped so you don't get unexpected streak resets while testing locally. To test a job manually, import and call it directly in a scratch script, e.g.:

```bash
npx tsx -e "import('./src/jobs/dailyReset.js').then(m => m.runDailyReset())"
```

### Production build

```bash
npm run build
npm start
```

---

## Running the Frontend

Flutter needs the Supabase URL/anon key and the API base URL injected at build/run time via `--dart-define` (see `lib/config/app_config.dart`):

```bash
cd apps/flutter_app

flutter run \
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs... \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

To avoid retyping these every time, create a `.vscode/launch.json` entry or a small shell script (`scripts/run_dev.sh`) that wraps the command above — don't commit real keys into either.

For Android emulator talking to a backend running on your host machine, `localhost` won't resolve from inside the emulator — use `10.0.2.2` instead:

```bash
--dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

For a physical device on the same Wi-Fi network, use your machine's LAN IP instead of `localhost`.

---

## Connecting Supabase

1. Create a project at [supabase.com](https://supabase.com) (free tier).
2. In the SQL Editor, run the migrations in order:
   ```sql
   -- paste contents of supabase/migrations/0001_init.sql, run it
   -- then paste contents of supabase/migrations/0002_notifications.sql, run it
   ```
   Or, if using the Supabase CLI locally:
   ```bash
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```
3. Under **Project Settings → API**, copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public key** → `SUPABASE_ANON_KEY` (Flutter)
   - **service_role key** → `SUPABASE_SERVICE_ROLE_KEY` (backend `.env` only — never ship this to the client)
4. Under **Project Settings → API → JWT Settings**, copy the **JWT Secret** → `SUPABASE_JWT_SECRET` (backend `.env`).
5. Under **Authentication → Providers**, email/password is enabled by default — no extra config needed for the auth flow as built. Email confirmation can be toggled off for local testing under **Authentication → Settings → Email Auth**.

Seed data (learning paths, lessons, quests, leagues, achievements) needs to be inserted separately — see Part H of this build series for seed SQL once available, or insert rows manually matching the schemas in `0001_init.sql`.

---

## Environment Variables

### Backend (`services/api/.env`)

| Variable | Required | Description |
|---|---|---|
| `NODE_ENV` | no (default `development`) | `production` enables cron jobs |
| `PORT` | no (default `3000`) | HTTP port |
| `LOG_LEVEL` | no (default `info`) | pino log level |
| `SUPABASE_URL` | **yes** | Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | **yes** | Service role key — full DB access, server-only |
| `SUPABASE_JWT_SECRET` | **yes** | Used to verify client-supplied JWTs |
| `ALLOWED_ORIGINS` | no | Comma-separated CORS allowlist |
| `RATE_LIMIT_MAX` / `RATE_LIMIT_WINDOW_MS` | no | Per-user rate limit |
| `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` | no | Push notifications; app runs fine without these, pushes are just skipped (still logged to `notifications_log`) |

### Frontend (`--dart-define` flags)

| Flag | Required | Description |
|---|---|---|
| `SUPABASE_URL` | **yes** | Same project URL as backend |
| `SUPABASE_ANON_KEY` | **yes** | Public anon key — safe to embed in client builds |
| `API_BASE_URL` | **yes** | Node API base, e.g. `https://api.mintro.app/api/v1` |

---

## Testing

Testing infrastructure is **not yet implemented** in this build — `vitest` is listed in `services/api/package.json` and `flutter_test` in `pubspec.yaml`, but no test files exist yet. Recommended starting points when adding tests:

- **Backend**: unit-test `lessonService.completeLesson`'s scoring logic (`scoreQuestion` for each question type) and `goalRepository`'s milestone-crossing math — these are pure functions with clear inputs/outputs. Integration-test the RLS policies directly against a local Supabase instance (`supabase start`) using two different JWTs to confirm cross-user isolation.
- **Frontend**: widget-test the score ring and progress bar animations don't throw on edge values (0%, 100%, negative clamps). Test `Profile.levelProgress`'s XP-to-level math against the same formula used server-side in `xp_to_level()` to catch drift between the two independent implementations.

---

## Deployment

### Backend

The API is a stateless Fastify app — any Node host works. Two common options:

**Railway / Render / Fly.io** (simplest):
1. Connect the repo, set the root directory to `services/api`.
2. Set build command `npm install && npm run build`, start command `npm start`.
3. Add all required env vars from the table above.
4. These platforms keep the process alive continuously, which is required for `node-cron` jobs to fire — don't deploy to a platform that spins down on idle (e.g. serverless functions) unless you move the cron jobs to that platform's own scheduler (e.g. a separate cron-triggered HTTP endpoint).

**Docker** (for more control):
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY dist ./dist
EXPOSE 3000
CMD ["node", "dist/server.js"]
```
Build with `npm run build` first so `dist/` exists, then `docker build` and push to your registry of choice.

### Frontend

**Android**:
```bash
cd apps/flutter_app
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=API_BASE_URL=https://api.mintro.app/api/v1
```
Output: `build/app/outputs/bundle/release/app-release.aab`, uploaded to Google Play Console.

**iOS**: requires a macOS machine with Xcode.
```bash
flutter build ipa --release --dart-define=...
```
Output goes to `build/ios/ipa/`, uploaded via Xcode Organizer or `xcrun altool`.

### Database

Supabase is already hosted — no separate deployment step. Promote schema changes by running new migration files against your production project (via SQL Editor or `supabase db push` with the production project linked).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Flutter app shows blank/crashes on launch | Missing `--dart-define` flags | Confirm all three (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`) are passed |
| `401 Unauthorized` from every API call | `SUPABASE_JWT_SECRET` mismatch | Confirm it matches the value under Project Settings → API → JWT Settings exactly |
| API calls succeed but XP never updates | Service role key wrong/missing | Confirm `SUPABASE_SERVICE_ROLE_KEY` is set in the backend `.env`, not the anon key |
| Android emulator can't reach local API | Using `localhost` from inside the emulator | Use `10.0.2.2` instead of `localhost` |
| RLS error: "new row violates row-level security policy" | Trying to update XP/coins/streak directly via the Supabase client instead of through the API | These columns are intentionally write-protected — route the mutation through the Node API |
| Cron jobs never fire | Running in `development` mode, or host spins down on idle | Set `NODE_ENV=production`; confirm host keeps the process alive continuously |
| Push notifications silently don't arrive | Firebase env vars not set | This is expected without them — pushes are skipped but still logged to `notifications_log`; add Firebase credentials to enable actual delivery |

---

## Maintenance

- **Monitoring**: none is wired up in this build. At minimum, add uptime monitoring on `/health` (e.g. a free tier of UptimeRobot or Better Stack) and forward `pino` logs somewhere persistent (a log drain on Railway/Render, or `pino` → a hosted log service) since logs are currently stdout-only and lost on restart.
- **Backups**: Supabase takes automatic daily backups on paid plans; the free tier does not include point-in-time recovery. If staying on the free tier past a real launch, schedule your own periodic `pg_dump` via the Supabase connection string.
- **Dependency updates**: `npm outdated` (backend) and `flutter pub outdated` (frontend) periodically. Pin major versions in `package.json`/`pubspec.yaml` as currently written; review changelogs before bumping `supabase_flutter` or `@supabase/supabase-js` specifically, since auth/session APIs occasionally change between major versions.
- **Migrations**: always additive where possible (new column with a default, new table) rather than destructive, so a bad deploy can roll back the app code without needing a matching schema rollback.

---

## Scaling

These are rough, directional estimates based on Supabase's published tier limits and typical Fastify throughput on small instances — not load-tested against this specific codebase.

| Users | Backend | Database | Notes |
|---|---|---|---|
| 10–100 | Single small instance (512MB–1GB RAM) | Supabase free tier | Free tier's 500MB DB and 50k monthly active user auth limit comfortably cover this |
| 1,000 | Same, maybe 1 vCPU | Supabase Pro ($25/mo) | Pro tier's daily backups become worth having at this point |
| 10,000 | 1–2 instances behind a load balancer | Supabase Pro, watch connection pool usage | Fastify is lightweight; the more likely bottleneck is Postgres connections — consider PgBouncer (Supabase offers this) |
| 100,000 | Horizontally scaled API, Redis-backed rate limiting (current rate limiter is in-memory and won't coordinate across instances) | Supabase Team/Enterprise, read replicas | Leaderboard snapshot writes (one row per league member per week) start mattering — consider batching the weekly rotation job |
| 1,000,000 | Dedicated infra, likely moving off Supabase's managed tiers to self-hosted Postgres or a larger committed-use plan | Custom Postgres scaling, dedicated read replicas, possibly sharding leaderboard data by league | At this scale, re-architect the weekly cron job — a single-process loop over every league member won't finish in a reasonable window |

The single most important early scaling note: **the current rate limiter (`@fastify/rate-limit`) is in-memory per-process**. The moment you run more than one API instance, rate limits stop being enforced correctly across instances. Swap to a Redis-backed store before horizontally scaling the backend.

---

## Security Notes

- XP, coins, level, and streak fields are write-protected from the client at the database level (RLS `with check` clause) — even a compromised or reverse-engineered client cannot self-grant rewards by calling Supabase directly. Only the Node API's service-role-authenticated calls to `award_xp_and_coins`/`update_streak` can change these.
- The Node API verifies every request's JWT signature against `SUPABASE_JWT_SECRET` before processing — there's no unauthenticated endpoint other than `/health`.
- The service role key has full database access and bypasses RLS entirely. It must never be embedded in the Flutter app or any client-side code, and should be rotated immediately if it's ever accidentally committed.
- Lesson quiz scoring happens server-side, not client-side, specifically so a modified client can't submit a forced "100% correct" result and claim full XP.
- GDPR/privacy compliance (data export, account deletion, a published privacy policy) is **not implemented** in this build and would need to be added before a public launch in any jurisdiction requiring it.

---

## Cost Estimates

Rough monthly figures, USD, as of this writing — confirm current pricing directly with each provider before budgeting, since these change periodically.

| Stage | Supabase | Backend hosting | Push (FCM) | Total |
|---|---|---|---|---|
| Prototype / pre-launch | $0 (free tier) | $0 (free tier on Railway/Render) | $0 (FCM is free) | **$0** |
| Early launch (~1k users) | $25 (Pro) | $5–20 | $0 | **~$30–45** |
| Growing (~10k users) | $25–599 depending on usage | $20–100 | $0 | **~$45–700** |
| Scale (~100k+ users) | Custom/Enterprise pricing — contact Supabase | $200+ across multiple instances | $0 | Highly variable; budget for a custom conversation with Supabase sales at this point |

FCM (push notifications) has no direct cost at any scale referenced here. App store fees ($99/year Apple, $25 one-time Google) and any payment processor fees for the not-yet-built premium subscription are separate from the above.

---

## Future Improvements

Roughly in the order they'd unblock the most value:

1. **Quiz-taking UI** — the highest-priority gap. The scoring endpoint and question-type models already exist; this is "just" the screens to actually answer multiple-choice/match-pairs/drag-drop questions and submit real `answers` payloads instead of the current empty-array placeholder.
2. **Achievement evaluation job** — a cron job (or triggered check after each XP-awarding action) that compares user stats against `achievements.requirement_value` and inserts `user_achievements` rows automatically, firing the existing `AchievementUnlockToast`.
3. **In-app notification center screen** — `notifications_log` is already populated by the backend; it just isn't rendered anywhere in the app yet.
4. **Friends/social** — schema and RLS exist; needs a friend-request UI and a friends-filtered leaderboard view.
5. **Premium subscription** — needs a payment provider (Stripe via Supabase Edge Functions, or RevenueCat for mobile-native billing), plus actual enforcement of the existing `is_premium` flags on paths/lessons.
6. **Redis-backed rate limiting** — required before running more than one backend instance (see Scaling section).
7. **Streak freeze purchase flow** — `streak_freeze_count` exists on `profiles` and is consumed correctly by the daily reset job, but there's no UI to spend coins to acquire one.
8. **GDPR tooling** — account deletion, data export, published privacy policy/terms — required before any public launch in the EU/UK and likely elsewhere.
