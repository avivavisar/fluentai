# FluentAI 2.0 — Milestone Tracker

Granular, independently-testable milestones. **Rule: each milestone is built, tested, and approved
before the next begins.** No skipped steps. Status legend: ✅ done · 🔵 in progress · ⛔ blocked · ⬜ not started.

> Plan reference: `.claude/plans/we-are-going-to-dreamy-rivest.md`. New backend: `backend-nest/` (NestJS).
> Old `backend/` (Fastify) kept as reference until parity.

---

## Product pillars (the differentiators — guide every milestone)

The product must feel like a **real private teacher**, not a chat app. Three first-class pillars + four
cross-cutting commitments, realized by the milestones tagged `[pillar]` below:

- **A — Learner model ("teacher's notebook")**: a living, structured model of each student (error
  fingerprints, acquired-vs-exposed vocab, engaging topics, pace/timing, motivation signals) that the
  tutor consults every session. → **M4.10**
- **B — Proactive teaching**: the tutor decides what you need next — a personalized daily plan and
  intentful session openers, not purely reactive chat. → **M4.11**
- **C — Real-time difficulty calibration (i+1)**: continuously read comprehension signals and auto-tune
  language level within a session. → **M4.12**
- Cross-cutting: **emotional/motivation engine** (M4.13), **natural in-conversation recycling** of due
  items (M4.14), **measurable progress proof** (M4.15), **real-world material bridge** (M5.8).

---

## Phase 0 — Commercial foundation

- **M0.1 — NestJS scaffold + health** ✅
  Fresh NestJS app, validated env, Prisma module, ported `AiService` (chat/placement/translate), Swagger, `/v1` prefix.
  *Test:* `nest build` clean; boots; `GET /health` → `{status:ok, db:not_configured, redis:disabled, ai:not_configured}`. **DONE & verified.**

- **M0.2 — Provision Supabase + Upstash, run first migration** ✅
  Supabase (eu-west-1) + Upstash provisioned; `backend-nest/.env` filled; first migration `0_init` applied via
  the non-interactive baseline (`migrate diff` → `migrate deploy`) — all tables + `vector` extension created.
  *Test passed:* `GET /health` → `{status:ok, db:up, redis:up}`. **DONE & verified.**
  *Dep:* M0.1.

- **M0.3 — Supabase auth guard + user mapping** ✅
  `AuthGuard` verifies the Supabase access token (hybrid: HS256 secret OR asymmetric via JWKS — Supabase
  signs user tokens ES256), JIT-provisions a local `User` (by `supabaseId`, links by email). `GET /v1/me`.
  Schema: `User.supabaseId` added, `passwordHash` now optional (migration `..._add_supabase_auth`).
  *Test passed:* valid token → 200 with user; second call reuses same id; bad/missing token → 401. **DONE.**
  *Dep:* M0.2.

- **M0.4 — Redis + BullMQ worker skeleton** ✅
  `@nestjs/bullmq` + `bullmq` on Upstash; `tasks` queue + `TasksProcessor` worker + `QueueService`;
  dev-only `POST /v1/debug/enqueue` & `GET /v1/debug/counts`. Dedicated BullMQ connection
  (`maxRetriesPerRequest: null`) built from `REDIS_URL`.
  *Test passed:* enqueue → `completed:1`; worker logged "Processing job 1 (echo)". **DONE.**
  *Dep:* M0.2.

- **M0.5 — Object storage (Supabase Storage)** ✅
  `StorageService` (supabase-js + service_role): auto-creates private `media` bucket on boot,
  `upload` + `signedUrl` helpers; dev-only `POST /v1/debug/storage/test`.
  *Test passed:* upload → signed URL → download; content matched exactly. **DONE.**
  *Dep:* M0.2.

- **M0.6 — CI/CD pipeline**
  GitHub Actions: install → lint → `nest build` → `prisma validate` on push/PR.
  *Test:* pipeline runs green; a deliberate type error fails the build.
  *Dep:* M0.1.

- **M0.7 — Observability (Sentry + PostHog)**
  Server-side Sentry error capture + PostHog event capture, behind env flags.
  *Test:* trigger a test error → appears in Sentry; emit a test event → appears in PostHog.
  *Dep:* M0.2.

- **M0.8 — Commercial schema extension** ✅
  Added `Subscription, Entitlement, UsageCounter, Device, ReferralCode, Referral` (+ enums + User
  relations); migration `..._commercial_schema` applied via baseline.
  *Test passed:* migrate deploy ok; `migrate diff --exit-code` → "No difference detected"; all new
  tables queryable. **DONE.** *Dep:* M0.2.

---

## Phase 1 — Core learning MVP (text)

- **M1.1 — Profile routes** ✅ — `GET/PATCH /v1/profile` (`src/profile/`): lazy default-create on GET, validated `UpdateProfileDto` on PATCH. *Test passed:* default profile created; patch persisted (goal/interests/support/name); invalid goal → 400. **DONE.** *Dep:* M0.3.
- **M1.2 — Onboarding persistence** ✅ — `POST /v1/profile/onboarding` (`CompleteOnboardingDto`, goal required) persists goal/interests/hebrew-support + sets `onboardingComplete`. *Test passed:* flag set + fields persisted; missing goal → 400. **DONE.** *Dep:* M1.1.
- **M1.3 — Placement test** ✅ — `GET /v1/placement/questions` (no answers leaked) + `POST /v1/placement/submit` → server-grades MC → `AiService.gradePlacement` (real Claude) → stores `PlacementTest`, upserts profile CEFR + support. **First AI-backed endpoint.** *Test passed:* 10 Qs no leak; Claude returned B1/0.82 with rationale; profile CEFR persisted. **DONE.** *Dep:* M1.1.
- **M1.4 — Conversation + chat turn** ✅ — `src/conversation/`: create/list/end conversation, `GET/POST :id/messages`; `POST` → `AiService.chatTurn` → persists user+assistant `Message`, `Correction[]` on the **user** msg, deduped `VocabItem[]`; ownership-checked. *Test passed:* deliberate errors → tutor reply with inline fix + comprehension check + **personalized** question (used onboarding interests), 2 bilingual GRAMMAR corrections (go→went, eat→ate), new vocab, CEFR B1. **DONE — core tutor live.** *Dep:* M1.1.
- **M1.5 — Vocab capture + list** — auto-save new vocab; `GET /v1/vocab`. *Test:* words from a chat turn appear in the list. *Dep:* M1.4.
- **M1.6 — Progress/dashboard endpoint** — CEFR, words learned, recent sessions. *Test:* values reflect prior activity. *Dep:* M1.4.
- **M1.7 — Flutter: Supabase auth** — login/signup + Google/Apple against Supabase; token wired to API client. *Test:* sign up in app → authenticated call succeeds. *Dep:* M0.3.
- **M1.8 — Flutter: onboarding + placement screens** — against new API. *Test:* complete flow → CEFR shown. *Dep:* M1.3, M1.7.
- **M1.9 — Flutter: chat screen** — bubbles + correction cards (EN↔HE toggle). *Test:* chat with an error → correction card appears. *Dep:* M1.4, M1.7.
- **M1.10 — Flutter: dashboard screen** — CEFR + stats + recent. *Test:* matches backend data. *Dep:* M1.6, M1.7.

---

## Phase 2 — Voice tutor

- **M2.1 — TTS endpoint (ElevenLabs)** — text → audio. *Test:* returns valid MP3. *Dep:* M1.4.
- **M2.2 — STT endpoint (Azure)** — audio → transcript. *Test:* spoken clip → correct text. *Dep:* M0.2.
- **M2.3 — Pronunciation assessment (Azure)** — audio + ref → accuracy/fluency/completeness + phonemes. *Test:* score returned. *Dep:* M2.2.
- **M2.4 — WebSocket voice pipeline** — STT → Claude → TTS over WS, with barge-in. *Test:* speak → spoken reply with low latency. *Dep:* M2.1, M2.2.
- **M2.5 — Recording + transcript persistence** — store audio in storage + transcript in DB. *Test:* replay a past turn. *Dep:* M2.4, M0.5.
- **M2.6 — "Say it like a native"** — native audio of corrected phrase + comparison. *Test:* play model audio; show your-vs-native. *Dep:* M2.3.
- **M2.7 — Flutter: voice-first talk screen** — call UX, mic, live transcript, states, feedback strip. *Test:* full spoken loop end-to-end. *Dep:* M2.4, M1.9.

---

## Phase 3 — AI companion + memory

- **M3.1 — Companion CRUD** — name/gender/role/persona/voice. *Test:* create/read/update companion. *Dep:* M1.1.
- **M3.2 — Embedding + pgvector store** — embed text, store `CompanionMemory.embedding`, cosine query. *Test:* insert memories → nearest-neighbor query returns relevant ones. *Dep:* M0.2.
- **M3.3 — Memory extraction worker** — end-of-conversation Claude extraction → embed → store. *Test:* finish a chat mentioning a fact → memory row created. *Dep:* M3.2, M0.4.
- **M3.4 — Memory retrieval into prompt** — inject retrieved memories into cached prefix. *Test:* companion recalls a fact in a new session. *Dep:* M3.3, M1.4.
- **M3.5 — Importance/decay + proactive greeting** — `expiresAt`/importance; greet by name on return. *Test:* stale memories decay; greeting uses remembered name. *Dep:* M3.4.
- **M3.6 — Flutter: memory transparency screen** — view/edit/delete memories. *Test:* delete a memory → no longer recalled. *Dep:* M3.4.

---

## Phase 4 — Learning system

- **M4.1 — XP engine + levels** — award XP per action; app-level curve. *Test:* action grants expected XP/level-up. *Dep:* M1.4.
- **M4.2 — Streaks + freeze tokens** — daily streak logic, freeze consumption. *Test:* simulate day gap with/without freeze. *Dep:* M4.1.
- **M4.3 — Daily missions** — generate + track + complete. *Test:* complete a mission → progress + reward. *Dep:* M4.1.
- **M4.4 — SRS (SM-2) reviews** — schedule + surface due items. *Test:* review grading reschedules due date correctly. *Dep:* M1.5.
- **M4.5 — Mistake engine** — aggregate `Mistake` patterns from corrections. *Test:* repeated error increments pattern count. *Dep:* M1.4.
- **M4.6 — Grammar mastery tracking** — per-topic mastery from mistakes/drills. *Test:* mastery updates with practice. *Dep:* M4.5.
- **M4.7 — Analytics dashboard data** — CEFR trend, weak areas, streak calendar, weekly assessment. *Test:* values reflect history. *Dep:* M4.2, M4.5.
- **M4.8 — Adaptive "next" recommendation** — pick next activity from weak areas + SRS load. *Test:* recommendation shifts with weak areas. *Dep:* M4.4, M4.5.
- **M4.9 — Flutter: gamification + analytics screens** — XP/streak/missions/reviews/analytics. *Test:* screens match backend. *Dep:* M4.7, M1.10.
- **M4.10 — Learner model ("teacher's notebook") `[pillar A]`** — unified structured model aggregating error fingerprints, acquired-vs-exposed vocab, engaging topics, pace/timing, motivation signals; injected into the tutor's cached prompt prefix. *Test:* model reflects recent sessions; tutor references a known weak area unprompted. *Dep:* M3.4, M4.5.
- **M4.11 — Proactive daily plan + intentful openers `[pillar B]`** — generate a per-user daily plan from the learner model + goals; tutor opens sessions with intent citing the day's focus. *Test:* plan adapts to weak areas; opener references the planned focus. *Dep:* M4.10, M4.8.
- **M4.12 — Real-time difficulty calibration (i+1) `[pillar C]`** — measure comprehension signals (repeat requests, response latency, error rate) and auto-tune target CEFR within a session. *Test:* simulated struggle lowers difficulty; fluent answers raise it. *Dep:* M1.4.
- **M4.13 — Emotional & motivation engine** — detect frustration/boredom/wins, adapt tone + encouragement; warm win-back for lapsed users. *Test:* frustration signal shifts tone/difficulty; win-back message generated for an inactive user. *Dep:* M4.2, M4.10.
- **M4.14 — Natural in-conversation recycling** — tutor reintroduces SRS-due vocab/grammar inside live chat (not just flashcards). *Test:* a due item reappears naturally in a generated turn and updates its SRS schedule. *Dep:* M4.4, M1.4.
- **M4.15 — Measurable progress proof** — periodic assessment + progress deltas (CEFR sublevel, per-skill accuracy trends) surfaced to the user. *Test:* report shows before/after deltas computed from history. *Dep:* M4.7.

---

## Phase 5 — Lessons, writing, listening

- **M5.1 — Lesson generation engine** — Claude → structured lesson (objective/teach/practice/check). *Test:* generate a CEFR-appropriate lesson. *Dep:* M1.3.
- **M5.2 — Nightly lesson pre-gen worker + cache** — pre-generate & store lessons. *Test:* worker fills lesson cache. *Dep:* M5.1, M0.4.
- **M5.3 — Grammar curriculum** — topic data + endpoints + just-in-time mini-explanations. *Test:* fetch topics; mistake triggers explanation. *Dep:* M4.6.
- **M5.4 — Writing correction** — submit text → corrected diff + categorized errors + rubric score. *Test:* error-laden text → diffs + EN/HE explanations + score. *Dep:* M1.4.
- **M5.5 — Listening exercises** — graded TTS clips + comprehension checks + speed control. *Test:* play clip → answer check graded. *Dep:* M2.1.
- **M5.6 — Personalized learning path** — ordered nodes that reorder by mistakes/SRS/progress. *Test:* path reorders as weak areas change. *Dep:* M4.8, M5.1.
- **M5.7 — Flutter: lessons/writing/listening/path screens.** *Test:* each flow works end-to-end. *Dep:* M5.4, M5.5, M5.6.
- **M5.8 — Real-world material bridge** — user brings their own content (an email to write, meeting prep, an article/video transcript) → tutor builds a tailored session around it. *Test:* paste an email draft → tutor coaches on that exact task with corrections. *Dep:* M5.1, M6.1.

---

## Phase 6 — Scenarios & advanced modes

- **M6.1 — Scenario engine** — persona + goal + flow layered on chat core. *Test:* scenario steers conversation. *Dep:* M1.4.
- **M6.2 — Scenario library** — interview, meeting, presentation, negotiation, networking, phone, travel set, doctor, small talk. *Test:* each scenario loads + runs. *Dep:* M6.1.
- **M6.3 — Story mode** — interactive narrative learning. *Test:* branching story turn works. *Dep:* M6.1.
- **M6.4 — Flutter: scenario UI** — picker + in-scenario chrome. *Test:* pick → guided roleplay with corrections. *Dep:* M6.2, M1.9.

---

## Phase 7 — Monetization

- **M7.1 — Tiers + entitlement gate** — `Entitlement` model + feature-gating guard. *Test:* gated route blocked on free, allowed on premium. *Dep:* M0.8.
- **M7.2 — Stripe (web)** — checkout + webhook → update `Subscription`. *Test:* sandbox purchase → entitlement flips to premium. *Dep:* M7.1.
- **M7.3 — RevenueCat (mobile IAP)** — purchase + entitlement sync to backend. *Test:* sandbox IAP → entitlement updates. *Dep:* M7.1.
- **M7.4 — Free-tier usage caps** — enforce `UsageCounter` (daily AI minutes/messages). *Test:* exceed cap → blocked with upgrade prompt. *Dep:* M7.1.
- **M7.5 — Paywall UX** — Flutter paywall + Next.js pricing page. *Test:* hitting a gate shows paywall; purchase unlocks. *Dep:* M7.2, M7.3.

---

## Phase 8 — Growth & notifications

- **M8.1 — Device token registration** — store FCM/APNs tokens on `Device`. *Test:* register from app → row saved. *Dep:* M0.8.
- **M8.2 — Push send + scheduled worker** — send push; scheduled-notification worker. *Test:* scheduled push arrives on device. *Dep:* M8.1, M0.4.
- **M8.3 — Transactional email** — provider util (welcome, reset, reports). *Test:* trigger → email received. *Dep:* M0.2.
- **M8.4 — Smart reminders** — streak-saver, due-reviews, daily-goal; quiet hours + prefs. *Test:* reminders respect prefs/timezone. *Dep:* M8.2, M4.4.
- **M8.5 — Referrals** — codes + reward on signup. *Test:* referred signup credits both. *Dep:* M0.8.
- **M8.6 — Weekly progress report** — generated + delivered (push/email). *Test:* report reflects week's activity. *Dep:* M4.7, M8.3.
- **M8.7 — A/B + onboarding optimization** — experiment framework (PostHog flags). *Test:* variant assignment + exposure logged. *Dep:* M0.7.
- **M8.8 — Next.js marketing site** — landing, pricing, blog, store/app links. *Test:* site builds, SEO meta, links to app. *Dep:* M7.5.

---

## Phase 9 — Production hardening & launch

- **M9.1 — Admin dashboard** — users, subscriptions, usage, content. *Test:* admin-only access; key ops work. *Dep:* M7.1.
- **M9.2 — Security hardening** — rate limits, input validation sweep, secret handling, dependency audit. *Test:* abuse attempts blocked; audit clean. *Dep:* M0.8.
- **M9.3 — Performance pass** — caching, context capping, query/index tuning, lazy load. *Test:* latency/throughput targets met. *Dep:* core phases.
- **M9.4 — GDPR: export + delete** — data export + full account deletion. *Test:* export returns user data; delete purges it. *Dep:* M0.8.
- **M9.5 — Infra & deploy** — containerize; deploy backend (Fly/Render → Fargate); managed Postgres/Redis; CDN. *Test:* staging environment serves the app. *Dep:* M0.6.
- **M9.6 — Store submission prep** — iOS + Android builds, store listings, screenshots, review compliance. *Test:* TestFlight/internal track build accepted. *Dep:* M9.4.
- **M9.7 — Legal** — privacy policy, terms, consent. *Test:* linked + enforced in apps. *Dep:* M9.4.
- **M9.8 — Launch** — production release on web + iOS + Android. *Test:* public install + purchase works. *Dep:* M9.5, M9.6, M9.7.

---

### Working agreement
1. I propose the next milestone (scope + exact test).
2. **You approve.**
3. I build it.
4. I run its test and show the result.
5. Only then do we move to the next.
