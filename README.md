# FluentAI

AI English tutor for Hebrew speakers. Flutter app + Node.js/TypeScript backend, PostgreSQL
(pgvector) + Redis, Claude for conversation/feedback, Azure Speech for voice.

This repo is built in **runnable increments** (see `.claude/plans/`). Current state:
**Increment 0 — Foundations** (project skeleton, DB, health check, app boots).

---

## Prerequisites (install these first)

The dev machine currently has only `git`. Install:

1. **Node.js 20+** — https://nodejs.org (includes `npm`)
2. **Docker Desktop** — https://www.docker.com/products/docker-desktop (runs Postgres + Redis)
3. **Flutter SDK 3.3+** — https://docs.flutter.dev/get-started/install (includes Dart)
   - Run `flutter doctor` and resolve any flagged items (Android Studio / Xcode for emulators).

---

## Repository layout

```
english/
  docker-compose.yml      # Postgres (pgvector) + Redis
  backend/                # Node.js + TypeScript (Fastify) API
  frontend/               # Flutter app
```

---

## 1) Start infrastructure (Postgres + Redis)

```bash
docker compose up -d
```

## 2) Backend

```bash
cd backend
copy .env.example .env        # Windows (or: cp .env.example .env)
# edit .env: set a strong JWT_SECRET. ANTHROPIC_API_KEY / Azure keys can stay empty until later.
npm install
npm run prisma:generate
npm run prisma:migrate        # creates tables + enables pgvector extension
npm run dev                   # starts on http://localhost:3000
```

Verify: open http://localhost:3000/health → should return
`{"status":"ok","db":"up","redis":"up"}`.

## 3) Frontend (Flutter)

```bash
cd frontend
flutter create .              # generates android/ ios/ etc. (keeps lib/ and pubspec.yaml)
flutter pub get
flutter gen-l10n              # generates lib/l10n/app_localizations.dart from the .arb files
flutter run                   # choose an emulator/simulator or device
```

Notes:
- Android emulator reaches the backend at `http://10.0.2.2:3000` (already the default).
- iOS simulator / desktop: run with `--dart-define=API_BASE_URL=http://localhost:3000`.
- Physical device: use your computer's LAN IP, e.g.
  `flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000`.

Verify: the app boots to a Hebrew (RTL) screen with a **"בדיקת חיבור לשרת"** button;
tapping it calls `/health` and shows the result.

---

## Keys you'll need as we progress
- `ANTHROPIC_API_KEY` — required from **Increment 1** (chat teacher, level test). Get one at
  https://console.anthropic.com
- `AZURE_SPEECH_KEY` + `AZURE_SPEECH_REGION` — required from **Increment 2** (real-time voice).

---

## Build roadmap (increments)
- **0 — Foundations** ✅ (this commit)
- 1 — Text chat teacher + bilingual EN↔HE corrections + level test + dashboard
- 2 — Real-time voice (Azure STT/TTS + pronunciation)
- 3 — AI Companion + long-term memory
- 4 — Learning system (XP, levels, SRS, analytics)
- 5 — Advanced scenario modes
- 6 — Production-minimal (polish, security, deploy guide)
