# Mintro — Complete Setup & Launch Tutorial

This tutorial assumes you have never built or shipped an app before. It walks through everything from installing tools on a blank machine to publishing on the App Store and Play Store, and what to expect as your user count grows.

**A note on scope before you start:** this tutorial gets you running the app *as it exists in this repository* — the gamification loop (lessons, XP, coins, streaks, quests, leagues, savings goals) works end-to-end against a real backend and database. It does not walk you through building the quiz-answering screens, the achievement-awarding job, friends, or premium subscriptions, because those aren't built yet (see the README's "Future Improvements" section). Where a part of this tutorial would require a feature that doesn't exist, that's called out explicitly rather than glossed over — you'll hit real walls if you follow store-publishing steps for a feature-incomplete app, so Part 6 in particular is written with that in mind.

---

## Table of Contents

- [Part 1: Installing Your Tools](#part-1-installing-your-tools)
- [Part 2: Creating Your Supabase Account](#part-2-creating-your-supabase-account)
- [Part 3: Running Mintro Locally](#part-3-running-mintro-locally)
- [Part 4: Testing on Devices](#part-4-testing-on-devices)
- [Part 5: Building Production Releases](#part-5-building-production-releases)
- [Part 6: Publishing to App Stores](#part-6-publishing-to-app-stores)
- [Part 7: Managing Updates](#part-7-managing-updates)
- [Part 8: Scaling Your User Base](#part-8-scaling-your-user-base)
- [Part 9: Ongoing Maintenance](#part-9-ongoing-maintenance)
- [Part 10: Growing the Business](#part-10-growing-the-business)

---

## Part 1: Installing Your Tools

You need six things on your machine: Flutter, Android Studio, VS Code, Git, Node.js, and (optionally) Python. None of the backend code in this project actually uses Python — the brief mentioned it as an option, but the implementation in Part C is Node.js/TypeScript throughout. Skip the Python install unless you plan to write your own tooling in it.

### 1.1 Git

**Windows**: download from [git-scm.com](https://git-scm.com/download/win), run the installer, accept the defaults.
**macOS**: open Terminal and run `git --version` — if it's not installed, macOS will prompt you to install Xcode Command Line Tools, which include Git.
**Linux**: `sudo apt install git` (Debian/Ubuntu) or your distro's equivalent.

Verify: open a terminal and run:
```bash
git --version
```
You should see something like `git version 2.43.0`.

### 1.2 Node.js

Install Node.js 20 or later from [nodejs.org](https://nodejs.org) — choose the LTS version. The installer includes `npm`.

Verify:
```bash
node --version   # should print v20.x.x or higher
npm --version
```

### 1.3 Flutter SDK

1. Go to [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) and download the SDK for your OS.
2. Extract it somewhere permanent (e.g. `~/development/flutter` on macOS/Linux, `C:\src\flutter` on Windows — avoid paths with spaces).
3. Add `flutter/bin` to your system PATH:
   - **macOS/Linux**: add `export PATH="$PATH:$HOME/development/flutter/bin"` to your `~/.zshrc` or `~/.bashrc`, then `source` it.
   - **Windows**: search "Environment Variables" in the Start menu, edit the `Path` variable under your user account, add the full path to `flutter\bin`.
4. Run the doctor command:
   ```bash
   flutter doctor
   ```
   This checks your setup and tells you what's missing. Don't worry if it shows warnings about Android/iOS toolchains yet — you'll fix those in the next two steps.

### 1.4 Android Studio

Even if you plan to write code in VS Code, Android Studio is needed for the Android SDK, emulator, and build tools.

1. Download from [developer.android.com/studio](https://developer.android.com/studio).
2. Run the installer, accept defaults, let it download the Android SDK on first launch.
3. Open Android Studio → **More Actions → SDK Manager** → confirm "Android SDK Platform" and "Android SDK Build-Tools" are checked under SDK Platforms/Tools.
4. Open **More Actions → Virtual Device Manager** → click **Create Device** → pick a phone profile (e.g. Pixel 7) → pick a system image (any recent one with a download icon, click to download it) → finish.
5. Run `flutter doctor` again — it should now show a green checkmark for Android toolchain. If it complains about licenses, run:
   ```bash
   flutter doctor --android-licenses
   ```
   and accept each one (type `y` repeatedly).

### 1.5 Xcode (macOS only, for iOS builds)

If you're not on a Mac, skip this — you cannot build or test iOS apps without one (this is an Apple requirement, not a Flutter limitation). Cloud Mac rental services exist (e.g. MacStadium) if you need iOS builds without owning a Mac.

1. Install Xcode from the Mac App Store (it's large — several GB, budget time for this).
2. Open Xcode once after installing to let it finish component installation.
3. Run:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app
   sudo xcodebuild -runFirstLaunch
   ```
4. `flutter doctor` should now show a green checkmark for Xcode.

### 1.6 VS Code

Download from [code.visualstudio.com](https://code.visualstudio.com). After installing, open the Extensions panel (`Ctrl+Shift+X` / `Cmd+Shift+X`) and install:
- **Flutter** (by Dart Code) — also installs the Dart extension automatically.
- **ESLint** — for the Node.js backend.

### 1.7 Final check

Run `flutter doctor` one more time. You want to see checkmarks (or at minimum, no blocking errors) for: Flutter, your IDE, Android toolchain, and (if on Mac) Xcode.

---

## Part 2: Creating Your Supabase Account

Supabase is where Mintro's database, authentication, and file storage live. The free tier is enough for everything in this tutorial.

### 2.1 Sign up

1. Go to [supabase.com](https://supabase.com) and click **Start your project**.
2. Sign up with GitHub (recommended, fastest) or email.

### 2.2 Create a project

1. Click **New Project**.
2. Choose an organization (Supabase creates a default personal one).
3. Fill in:
   - **Name**: `mintro` (or anything you like)
   - **Database Password**: generate a strong one and **save it somewhere** — you'll need it if you ever connect a database tool directly.
   - **Region**: pick whichever is geographically closest to your expected users.
4. Click **Create new project**. This takes a minute or two to provision — Supabase shows a progress screen.

### 2.3 Run the database schema

Once the project is ready:

1. In the left sidebar, click the **SQL Editor** icon.
2. Click **New query**.
3. Open `supabase/migrations/0001_init.sql` from this repository in a text editor, copy its entire contents, paste into the SQL Editor.
4. Click **Run** (or press `Ctrl+Enter`/`Cmd+Enter`).
5. You should see "Success. No rows returned" at the bottom. If you see a red error instead, read it carefully — the most common cause is running the file twice (extensions/types already exist). If that happens, you can safely ignore "already exists" errors, but stop and investigate any other error type before proceeding.
6. Repeat steps 2–5 for `supabase/migrations/0002_notifications.sql`.

### 2.4 Verify the tables exist

In the left sidebar, click **Table Editor**. You should see tables including `profiles`, `learning_paths`, `lessons`, `quests`, `goals`, `achievements`, `leagues`, and more. If the list looks empty, the migration didn't run — go back to 2.3.

### 2.5 Configure authentication

1. Left sidebar → **Authentication → Providers**.
2. Confirm **Email** is enabled (it is by default).
3. For local development, go to **Authentication → Settings** and consider turning **Confirm email** off temporarily, so you can sign up and immediately log in without checking an inbox. Turn this back on before any real launch.

### 2.6 Get your API keys

1. Left sidebar → **Project Settings** (gear icon) → **API**.
2. Note down three values, you'll need them shortly:
   - **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - **anon public** key (a long string starting with `eyJ...`)
   - **service_role** key (also starts with `eyJ...` — this one is secret, treat it like a password, never put it in the Flutter app)
3. Still in Project Settings, click **API → JWT Settings**, and note the **JWT Secret**.

### 2.7 Storage (for avatars — not yet used by the app, but configured for when it is)

1. Left sidebar → **Storage** → **Create a new bucket**.
2. Name it `avatars`, leave it private for now (the app doesn't yet have an avatar upload feature, so there's no public-read use case to configure yet).

---

## Part 3: Running Mintro Locally

### 3.1 Get the code

```bash
git clone <your-repo-url> mintro
cd mintro
```

### 3.2 Set up and run the backend

```bash
cd services/api
npm install
cp .env.example .env
```

Open the new `.env` file and fill in the values you collected in Part 2:

```
SUPABASE_URL=https://abcdefgh.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...your-service-role-key...
SUPABASE_JWT_SECRET=your-jwt-secret-from-2.6
```

Leave everything else at its default for now. Then start the server:

```bash
npm run dev
```

You should see log output ending in something like:
```
Mintro API listening on port 3000 (development)
Scheduled jobs skipped in non-production environment
```

Open a second terminal and confirm it's responding:
```bash
curl http://localhost:3000/health
```
Expected output: `{"status":"ok","timestamp":"2026-..."}`. Leave this terminal running — you need the backend up the whole time you're testing the app.

### 3.3 Set up and run the Flutter app

Open a **third** terminal:

```bash
cd mintro/apps/flutter_app
flutter pub get
```

Now run the app. Use the **anon** key (not the service role key — that one is for the backend only), and point `API_BASE_URL` at your locally running backend:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://abcdefgh.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...your-anon-key... \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

If you have multiple devices/emulators connected, `flutter run` will ask you to pick one — type the number shown next to your target.

You should see the Mintro login screen. There's no account yet, and this build doesn't include a separate "Sign Up" screen — for now, create your first account directly in Supabase:

1. Go to your Supabase dashboard → **Authentication → Users** → **Add user** → **Create new user**.
2. Enter an email and password.
3. Go back to the app and log in with those same credentials on the login screen.

You should land on the Home screen. It will look mostly empty (no lessons, no quests, no leagues) because **no seed data has been inserted yet** — Part H of this build series covers seed data; without it, the screens will render but show empty states or loading spinners that never resolve into real content. This is expected at this stage and not a bug in what you've set up.

### 3.4 Quick sanity check this is all wired correctly

With seed data absent, the most useful thing to verify right now is that auth and the API connection both work:
- Logging in successfully (no error message) confirms Supabase Auth + your anon key are correct.
- Pulling to refresh on the Home screen without an error toast confirms the app can reach both Supabase directly and your local API.

If login fails, double check the anon key. If the app loads but every screen shows a generic error, double-check `API_BASE_URL` and that the backend terminal from 3.2 is still running.

---

## Part 4: Testing on Devices

### 4.1 Android Emulator

If you created a virtual device in Part 1.4, you can launch it directly:

```bash
flutter emulators --launch <emulator_id>
```
(Run `flutter emulators` with no arguments first to see the IDs available.)

Once it's booted, run the app as in 3.3. One critical difference: **the Android emulator cannot reach `localhost` on your host machine** — it has its own network namespace. Use `10.0.2.2` instead, which Android's emulator maps back to your host:

```bash
--dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

### 4.2 Physical Android device

1. On the device: **Settings → About Phone** → tap **Build Number** seven times to enable Developer Options.
2. **Settings → Developer Options** → enable **USB Debugging**.
3. Connect via USB. Your computer may prompt you to allow USB debugging — accept on the device's screen.
4. Run `flutter devices` to confirm it's detected.
5. Run the app as in 3.3, but use your computer's LAN IP (not `localhost` or `10.0.2.2`) for `API_BASE_URL`, since the phone is a separate device on your network:
   ```bash
   # find your LAN IP first:
   # macOS/Linux: ifconfig | grep "inet "
   # Windows: ipconfig
   --dart-define=API_BASE_URL=http://192.168.1.XXX:3000/api/v1
   ```
   Both your computer and phone must be on the same Wi-Fi network.

### 4.3 iOS Simulator (macOS only)

```bash
open -a Simulator
flutter run --dart-define=...
```
`localhost` works fine from the iOS Simulator (unlike Android's emulator) since it shares the host's network namespace.

### 4.4 Physical iOS device

This requires an Apple Developer account (free tier works for device testing, paid $99/year tier is required for App Store distribution — see Part 6).

1. Connect the device via USB, trust the computer when prompted.
2. Open `apps/flutter_app/ios/Runner.xcworkspace` in Xcode.
3. Select your device from the device dropdown at the top.
4. Under **Signing & Capabilities**, select your Apple ID team.
5. Click the Run button in Xcode, or go back to terminal and run `flutter run` with your device selected.

---

## Part 5: Building Production Releases

### 5.1 Android APK (for direct distribution/testing, not Play Store)

```bash
cd apps/flutter_app
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://abcdefgh.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

Note the `API_BASE_URL` here points at a **deployed** backend, not `localhost` — a release build that ships to real users needs a real, publicly reachable backend (see Part 6 for deployment, or jump ahead to the README's Deployment section).

Output: `build/app/outputs/flutter-apk/app-release.apk`. This file can be installed directly on any Android device (with "install from unknown sources" allowed) — useful for sharing a test build before going through Play Store review.

### 5.2 Android App Bundle (required for Play Store)

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=API_BASE_URL=...
```

Output: `build/app/outputs/bundle/release/app-release.aab`. This is the file you upload to Google Play Console, not the APK.

**Before your first release build**, you need a signing key — Android won't let you publish an unsigned app bundle to the Play Store. Generate one:

```bash
keytool -genkey -v -keystore ~/mintro-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias mintro
```
Follow the prompts (set a password, your name, organization — these can be anything). **Back up this `.jks` file somewhere safe** — if you lose it, you cannot update your app on the Play Store ever again under the same listing; you'd have to publish as a brand new app.

Then create `apps/flutter_app/android/key.properties`:
```properties
storePassword=<password you set>
keyPassword=<password you set>
keyAlias=mintro
storeFile=/absolute/path/to/mintro-release-key.jks
```
And reference it in `apps/flutter_app/android/app/build.gradle` per the [official Flutter Android signing guide](https://docs.flutter.dev/deployment/android#signing-the-app) — the exact gradle edits depend on your Flutter/Gradle version, so follow that page directly rather than a pasted snippet that might be stale by the time you read this.

### 5.3 iOS build (macOS only)

```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=API_BASE_URL=...
```

Output: `build/ios/ipa/*.ipa`. This requires your Apple Developer account to be properly configured in Xcode first (Part 4.4's signing setup, but with a distribution certificate rather than a development one — Xcode's "Automatically manage signing" handles this distinction for you in most cases).

---

## Part 6: Publishing to App Stores

**Read this before starting**: as of this build, Mintro's quiz-taking UI is not implemented — lessons currently "complete" via a placeholder empty answer submission rather than an actual quiz interaction (see README → Features → Scaffolded but not fully built). Submitting an app in this state for review is very likely to either get rejected for being non-functional/incomplete, or to pass review but disappoint real users immediately. **Build the quiz UI (and ideally the achievement-awarding job and seed data) before going through this part for real.** The steps below are accurate regardless, so you can follow them once the app is actually ready, but it's worth saying clearly: this is a "how to publish" guide, not confirmation that this specific codebase is launch-ready today.

### 6.1 Google Play Store

**Developer account** ($25 one-time fee):
1. Go to [play.google.com/console](https://play.google.com/console/signup) and sign up with a Google account.
2. Pay the $25 registration fee.
3. Verification can take anywhere from a few hours to a few days.

**Creating the listing**:
1. Play Console → **Create app**. Fill in app name, default language, app/game toggle (app), free/paid.
2. Under **Store presence → Main store listing**, provide: short description (80 chars), full description (4000 chars), screenshots (minimum 2, recommended 4-8, exact dimensions vary by device class — Play Console shows current requirements when you upload), a feature graphic (1024×500px), and an app icon (512×512px).
3. Under **Policy → App content**, complete the required declarations: privacy policy URL (**you need to write and host one** — this is not optional, and Mintro as built has no privacy policy document; you'll need to create one covering what data Supabase Auth collects, how XP/financial-goal data is stored, etc.), content rating questionnaire, target audience, data safety form (be accurate — this form asks specifically what data you collect and why, and Google does check this against your actual app behavior).
4. Under **Release → Production**, create a new release, upload your `.aab` file from 5.2, fill in release notes, submit for review.

**Common rejection reasons**: missing or inaccurate privacy policy, data safety form not matching actual app behavior, broken core functionality (this is the risk flagged at the top of this section), misleading screenshots, requesting permissions the app doesn't actually use.

**Review time**: typically a few hours to a few days for the first submission; can take longer if flagged for manual review.

### 6.2 Apple App Store

**Developer account** ($99/year):
1. Go to [developer.apple.com/programs](https://developer.apple.com/programs/) and enroll.
2. Apple requires identity verification — for an individual, this is usually fast; for an organization, it can take longer since Apple verifies the business itself (D-U-N-S number, etc.).

**App Store Connect setup**:
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps** → **+** → **New App**.
2. Fill in platform (iOS), name, primary language, bundle ID (must match what's configured in Xcode under `apps/flutter_app/ios/Runner.xcodeproj`), SKU (any internal identifier).
3. Under the app's listing, provide: screenshots for each required device size (Apple is stricter than Google about exact required sizes — check current requirements in App Store Connect, they change periodically), description, keywords, support URL, marketing URL (optional), privacy policy URL (same requirement as Android — you need one written and hosted).
4. Under **App Privacy**, complete Apple's nutrition-label-style data collection disclosure — similar intent to Google's data safety form, different format.
5. Upload your build: either drag the `.ipa` from 5.3 into Xcode's Organizer and use "Distribute App," or use `xcrun altool --upload-app` from the command line.
6. Once the build appears in App Store Connect (can take 15 minutes to a few hours to process after upload), attach it to your app version and submit for review.

**Common rejection reasons**: Apple's "Guideline 2.1 — App Completeness" (the same broken/incomplete-functionality risk as Google), missing privacy policy, crashes on launch, login walls with no way to test without creating an account (Apple reviewers need to actually be able to log in — consider providing demo credentials in the App Review notes field if your app requires an account), use of placeholder/lorem-ipsum content visible to the reviewer.

**Review time**: historically 24-48 hours for most apps, though this varies.

### 6.3 Terms of Service & Privacy Policy

Both stores require these, and Mintro as built doesn't ship with either document. At minimum, a privacy policy needs to disclose: what data you collect (email via Supabase Auth; financial goal amounts and names; lesson/XP/streak activity), why (account function, gamification features), where it's stored (Supabase, hosted in [your project's region]), whether it's shared with third parties (Firebase, if you enable push notifications), and how users can request deletion. Templates exist (e.g. via [termly.io](https://termly.io) or a lawyer if you want one reviewed professionally) but writing one that accurately reflects an app's *actual* data handling — not a generic template's assumptions — matters for both legal compliance and avoiding store rejection for mismatched disclosures.

---

## Part 7: Managing Updates

### 7.1 Versioning

Flutter's `pubspec.yaml` has a `version: 1.0.0+1` line — the part before `+` is the user-facing version (semantic versioning: major.minor.patch), the part after is the build number, which **must increase on every single submission** to either store, even for a version string that doesn't change.

```yaml
version: 1.0.1+2  # bumped both the patch version and build number
```

### 7.2 Database migrations

Add new schema changes as new files: `supabase/migrations/0003_your_change.sql`. Run them against production the same way you ran `0001` and `0002` in Part 2.3 — paste into the SQL Editor and run, or `supabase db push` if using the CLI with your production project linked. Prefer additive changes (new nullable column, new table) over destructive ones (dropping a column, renaming something in use) so that if you need to roll back the *app* code without rolling back the *schema*, old app code doesn't break against a half-migrated database.

### 7.3 Releasing a new build

1. Make your code changes.
2. Bump the version in `pubspec.yaml`.
3. Build per Part 5.
4. Upload to Play Console / App Store Connect as a new release on top of the existing app listing (not a new app).
5. For backend changes with no corresponding app changes (e.g. a quest-scoring bug fix), just redeploy the API — no app store review needed at all, since the backend isn't distributed through either store.

### 7.4 Analytics and crash reporting

Neither is wired into this build. For a real launch, consider:
- **Crash reporting**: Firebase Crashlytics (pairs naturally since FCM is already used for push) or Sentry.
- **Analytics**: Firebase Analytics, PostHog, or Mixpanel — none currently integrated; would need the relevant Flutter package added and initialized in `main.dart`.

---

## Part 8: Scaling Your User Base

This expands on the README's scaling table with more day-to-day operational detail at each stage.

**10 users**: this is "you and your friends testing." Free tier of everything. No action needed beyond what's already set up.

**100 users**: still comfortably on free tiers. Worth doing now while traffic is low: set up basic uptime monitoring on your backend's `/health` endpoint (a free account on UptimeRobot takes five minutes) so you find out about an outage from a monitor, not from a user complaint.

**1,000 users**: Supabase's free tier (500MB database, 50,000 monthly active auth users) likely still covers you on the auth side, but database size and the lack of automatic backups on free tier become real considerations. Upgrade to Supabase Pro ($25/month) for daily backups and higher limits. Your backend can likely still run on a single small instance.

**10,000 users**: this is where the in-memory rate limiter flagged in the README becomes a real problem *if* you've scaled to multiple backend instances by this point. Before adding a second instance, swap `@fastify/rate-limit`'s storage to Redis (the package supports a `redis` store option) so rate limits are enforced consistently across instances rather than each instance tracking its own counts independently.

**100,000 users**: the weekly league-rotation cron job (Part C, `weeklyLeagueRotation.ts`) currently loops through every league member sequentially in a single process. At this scale, that loop's runtime starts mattering — if it can't finish within whatever window you've scheduled it for, leaderboard snapshots for late-processed leagues become stale relative to early-processed ones. Consider batching the job (process leagues in parallel, or split across multiple scheduled invocations) before this becomes painful.

**1,000,000 users**: you're well past what this tutorial can responsibly advise on in the abstract — at this point you likely have, or need, a dedicated infrastructure engineer making decisions specific to your actual traffic patterns, not a generic tutorial. Generic advice that would likely apply: read replicas for Postgres, evaluating whether Supabase's managed offering still fits your cost/control tradeoffs versus self-hosting, and sharding leaderboard data by league so no single query scans the entire user base.

---

## Part 9: Ongoing Maintenance

### 9.1 Monitoring

At minimum: uptime checks on `/health` (Part 8), and forwarding backend logs somewhere persistent — currently `pino` logs go to stdout only, which most hosting platforms capture temporarily but don't retain long-term by default. Most platforms (Railway, Render) offer a log drain or integration with a hosted log service (e.g. Better Stack, Datadog) — check your specific host's docs for "log forwarding" or "log drains."

### 9.2 Backups

Supabase Pro and above include daily automated backups. On the free tier, there are none — if that matters to you before upgrading, run manual backups yourself:
```bash
# requires the Supabase CLI and your project's connection string
supabase db dump -f backup_$(date +%Y%m%d).sql
```
Store the resulting file somewhere outside Supabase itself (cloud storage, a private repo, etc.) — a backup stored only in the same place as the thing it's backing up isn't much of a backup.

### 9.3 Supabase maintenance

Supabase occasionally schedules maintenance windows for infrastructure upgrades — these are announced in advance via your project's dashboard and email. No action is typically needed on your end beyond awareness that a brief window of downtime may occur.

### 9.4 Security updates

Run `npm audit` periodically in `services/api` to catch known vulnerabilities in dependencies, and `flutter pub outdated` in `apps/flutter_app` for the Flutter side. Treat anything flagged as "high" or "critical" severity as a near-term priority to patch, not something to defer indefinitely.

---

## Part 10: Growing the Business

### 10.1 User acquisition

Mintro's natural acquisition angle is content-driven: the lesson topics themselves (inflation, credit scores, index funds) are searchable, shareable concepts. Short-form video explaining one lesson's worth of content with a call-to-action to the app is a common playbook for finance-education apps specifically. Paid acquisition (app install ads) is also standard but requires a clear understanding of your cost-per-install versus lifetime value before spending meaningfully — don't start paid spend before you have at least rough retention numbers from organic users.

### 10.2 Retention

The streak mechanic (already built) is the primary retention lever — Duolingo's own public commentary on their growth attributes a significant share of retention to streak psychology specifically. The daily reminder push notification (already built in `dailyReset.ts`'s `runDailyReminder`) reinforces this, but only once Firebase credentials are configured (see README's Environment Variables) — without them, that job runs and logs the reminder but never actually delivers a push, silently reducing its own effectiveness.

### 10.3 Referral system

Not built. If adding one, the natural shape given the existing schema: a `referrals` table tracking referrer/referee pairs, a unique referral code per user (could live on `profiles`), and a coin/XP bonus to both parties on the referee's first lesson completion — which is a query you can hook into `lessonService.completeLesson`'s existing flow rather than building a separate system.

### 10.4 Community building

Discord or a similar community space is the common pattern for apps with a learning/improvement angle — gives users a place to ask questions about the financial concepts being taught, which doubles as a source of ideas for new lesson content.

### 10.5 Premium subscriptions

Not built (see README → Future Improvements). When you do build this, the two realistic paths are Stripe (more control, more integration work, works for both platforms uniformly) or RevenueCat (faster to integrate, handles App Store/Play Store billing complexity for you, takes a small cut). Given this app is mobile-first, RevenueCat is the more common choice for a first version.

### 10.6 Growth roadmap

A reasonable sequencing, building on the README's prioritized future-improvements list: ship the quiz UI and seed content first (nothing else matters if the core loop isn't real), then achievement evaluation (cheap to build, meaningfully increases the "game" feeling), then the notification center screen (the data already exists, it's just not rendered), then friends/social (increases retention through social accountability), then premium (monetization should follow proven retention, not precede it).
