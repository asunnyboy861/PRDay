# PRDay - iOS Development Guide

> Translated & expanded from the Chinese operation guide `TR-20261013-田径训练PRDay-操作指南.MD` (2026-10-13)

## Executive Summary

**PRDay** is the first US track & field training app that "reads the weather like a coach." Every day it generates and adjusts training based on WBGT heat risk (NATA/ACSM public standards), the athlete's event group and level, and days to the goal race. Parents automatically receive a weekly progress report every Sunday at 7 PM (zero setup, read-only via CloudKit sharing). Athletes film a short running video and get an AI form diagnosis (on-device Vision skeleton extraction + GLM-5.3-Flash visual reasoning via Cloudflare Worker proxy).

- **Target audience**: US middle school / high school / college track & field athletes and their parents (English UI only). Market size: 1.158M high school outdoor track athletes (NFHS 2024-25) across 17,373 schools.
- **Slogan**: "Make every meet a PR Day."
- **Key differentiators vs 3AK Track ($20K MRR validated competitor)**:
  1. WBGT heat-adaptive training plans (no competitor has this)
  2. Parent weekly report via CKShare read-only sharing (no competitor has this)
  3. AI form diagnosis, repeatable (3AK's is buggy, single-use)
  4. Data reliability: local-first SwiftData, streaks never silently reset
  5. Personalization engine: event group × level × periodization phase, VDOT/Riegel pace math
- **Bundle ID**: `com.zzoutuo.PRDay` (preset prefix `com.zzoutuo.` from `.env`; the guide suggests no alternative)
- **Min iOS**: 17.0 (Apple Intelligence on-device AI activates on iOS 26+; BYO API key fallback below)
- **Monetization**: Free tier + PRDay Pro subscription $7.99/month or $49.99/year (7-day free trial). No lifetime purchase (GLM vision API is a consumable cost → quota-based or BYO key).

## Competitive Analysis

| App | Pricing | Strengths | Weaknesses | Our Advantage |
|-----|---------|-----------|------------|---------------|
| 3AK Track | Free + $6.99/wk / $9.99/mo / $29.99/yr | 50K+ users, 4.8★ (827 ratings), athlete-founded, strong IG marketing | One-size-fits-all plans; buggy gait analysis (single upload); streak resets; no parent view; no coach/team view; no weather; post-season churn | WBGT adaptive plans, parent weekly reports, repeatable AI form checks, streak never resets |
| TrackIt: Track & Field | Free + Pro sub | Weather logging, wind correction, PB timeline | Records only, doesn't coach; very few ratings | Full coaching plans + heat guidance, not just logging |
| V.O2 (VDOTO2) | $14.99/mo, $119.99/yr | Jack Daniels VDOT authority, serious adult runners | Adult-focused, expensive, not teen/high-school oriented | Teen-first UX, $49.99/yr, parent visibility |
| Runna (Strava) | $19.99/mo, $119.99/yr | Polished UX, big brand | Plans feel "pre-baked," not personalized; running-only | Track & field specific (sprints/jumps/throws), plan engine adapts daily |
| Trackster | Free | Coach/team platform | Dated features | Modern SwiftUI, AI + weather + parent stack |
| TeamBuildr / TrainHeroic | $90-280/mo | B2B team strength platforms | Far too expensive for families; no track skill plans | Consumer-priced ($1.16/week equivalent) with team-ready architecture |
| Future (human coach) | $199/mo | Real human coaching | 48× our annual price | $49.99/yr ≈ half of one private session |
| Tully / LOKR Sports | Paid | Parent-visibility products validated demand | Not track-specific | Track-only parent reporting with training context |

**Pricing intelligence**: 3AK cut annual $59.99→$29.99 and tripled conversion → high-schooler psychological line < $60/yr. GLM is a consumable API → GLM features MUST be quota-based or BYO-key, never lifetime. Apple on-device AI is free → can be unlimited for Pro.

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Onboarding (≤60s) | 1. Launch → hero "MAKE EVERY MEET A PR DAY" → 2. Tap role: Athlete or Parent → 3. (Athlete) tap event group icon (Sprints/Mid-Dist/Jumps/Throws) → 4. Swipe level: First Season/Varsity/Elite → 5. One-tap weather+notification permission (with "why" copy) → 6. First week plan generated, today highlighted, CTA "Start Today's Workout" | Role, eventGroup, level | Create AthleteProfile; generate Week 1 plan via PlanEngine; request WeatherKit + local notification auth | Generated plan, today card highlighted | SwiftData: AthleteProfile, PlanDay | Fresh install → training card visible in ≤60s with zero typing; all tap-only |
| 2 | Today tab (home) | 1. Open app → today's workout card is FIRST screen element → 2. Heat flag chip shows color → 3. Tap "Start" | Current date, location (weather), profile | WeatherKit fetch → WBGTEngine → HeatFlag → PlanAdjustmentEngine rewrites today's PlanDay | Today card (title, sets×reps×target paces, flag color, one-line NATA rationale) | SwiftData PlanDay (adjusted instance cached) | Card visible without navigation; flag colors map to green/yellow/orange/red/black; offline shows cached plan + "coach's call" note |
| 3 | WBGT heat engine | Automatic; no user action | WeatherKit temp/humidity/radiation/wind | WBGT = 0.567·Ta + 0.393·e + 3.94 (outdoor simplified, °C/hPa); classify by NATA thresholds | Flag + activityRule text | In-memory + cached ≤3h | Simulated inputs: <82°F green, 82-86.9 yellow, 87-89.9 orange, 90-92.1 red, ≥92.2 black; degradation chain never blank |
| 4 | Weather-adaptive plan rewrite | Automatic on Today load (Pro rewrites; free sees flag only) | PlanDay + HeatFlag + daysToRace | Rules: yellow → work:rest 2:1 +3 breaks/h; orange → 1:1, high-intensity → technique day/7AM note; red/black → indoor-only, parent push; taper ≤7 days → volume ×0.6 | Adjusted PlanDay + rationale line | SwiftData adjusted PlanDay | 5 simulated weather inputs produce 5 correct rewrites (M3 acceptance) |
| 5 | Workout player | 1. Tap Start on today card → 2. Fullscreen: current set large type, rest countdown → 3. Screen stays awake, haptic on transitions → 4. Tap "Log" when done | Planned sets/reps/paces; optional RPE 1-10 | Interval timer state machine; idempotent log via clientUUID | Logged WorkoutSession with weather snapshot | SwiftData WorkoutSession (@Attribute(.unique) clientUUID) | Screen never sleeps during session; double-tap Log creates ONE record (idempotent); RPE slider 1-10 |
| 6 | PR tracking | 1. PRs tab → 2. Event picker → 3. Add PR (mark + date + wind-assisted toggle) → 4. Timeline + Swift Charts PB curve | Event, mark (sec or meters), date, windAssisted | Store PersonalRecord; PB = best legal mark (windAssisted excluded from official PR); timeline sorted desc | PB curve chart, event timeline | SwiftData PersonalRecord | Free tier: first 3 events only; Pro: all events; wind-assisted marks flagged visually, not counted as official PR |
| 7 | PR celebration | Auto on new PR at log time → fullscreen confetti + heavy haptic (UINotificationFeedbackGenerator .success) → share card (pace/event/improvement) → ShareLink to Instagram Story | New mark vs old PR | Detect PR on log; render 9:16 share card with PRDay watermark (free) or clean/custom (Pro) | Fullscreen celebration, shareable image | Rendered on demand | 60fps animation; watermark on free tier; Pro removes watermark |
| 8 | Streak engine | Automatic; visible flame in Today header | WorkoutSession dates | Versioned StreakState (append-only StreakEvent audit); missed days → repair questionnaire (makeup within 3 days) instead of auto-reset | Streak count, flame UI | SwiftData StreakState + StreakEvent | NO operation path can silently zero the streak; makeup flow restores continuity; version only increments |
| 9 | Plan tab (Pro) | 1. Plan tab → 2. Week view swipe → 3. Tap day → detail (sets, paces, purpose) → 4. Periodization phase indicator | eventGroup, level, plan length 12-16 weeks | PlanEngine: event group × level × phase (base/build/peak/taper) generates full plan; PaceEngine VDOT/Riegel computes target paces from PRs | Weekly plan view, phase progress | SwiftData PlanDay set | 4 event groups × 12-16 week plans generate; VDOT unit test passes; pace zones E/M/T/I/R correct |
| 10 | Parent weekly report (Pro) | 1. Me → Family Sharing → 2. Generate CKShare invite → 3. Parent accepts → 4. Sunday 7PM local push → 5. Parent opens read-only report card | Week's WorkoutSessions, PRs, completion % | Aggregate weekly stats; render shareable 9:16 report card; CKShare root record with parent as readOnly participant | Report card (completion 5/5, new PRs, next-week focus) | CloudKit private DB + CKShare; SwiftData WeeklyReport snapshot | Parent sees read-only report with zero athlete action; heart-rate details NOT in shared zone (only completion + PBs); Sunday 7PM push fires |
| 11 | Meet-day checklist (Pro) | 1. Plan tab or Today → "Meet Day" → 2. Checklist sections: nutrition/sleep/equipment/warmup → 3. Check items | daysToRace | Static checklist content filtered by event group | Interactive checklist | SwiftData MeetChecklistState | All 4 sections present; states persist; shown automatically within 7 days of race date |
| 12 | AI form diagnosis | 1. Me or PRs → "Form Check" → 2. Record/upload ≤10s running video → 3. On-device Vision extracts skeleton frames (knee angle, trunk lean, ground contact) → 4. Annotated frames → GLM-5.3-Flash via Worker → 5. Report: 3 strengths, 3 fixes with drills, safety note | Video file | Vision VNDetectHumanBodyPoseRequest per 0.5s frame over 6s; PoseFeatures; GLM vision chat (OpenAI-compatible); on-device feature report fallback if GLM fails | Diagnosis report card | Frames processed then discarded immediately; report text saved | Free 1/week, Pro 8/month, BYO unlimited; GLM timeout/failure → instant on-device fallback report, never infinite spinner; video never leaves device (only annotated JPEGs) |
| 13 | AI coach Q&A | 1. Today/Plan → "Ask Coach" → 2. Free-text question about training data → 3. Answer | Question + local training context | AICoachRouter: Apple Foundation Models on-device (iOS 26+); fallback template engine; never routes chat to GLM | Conversational answer | Session-scoped; optional transcript save | Free 1/day, Pro unlimited; iOS <26 → BYO key path or template fallback; no dead-end error states |
| 14 | Me tab & settings | 1. Me tab → profile edit (event group/level/goal race/date) → parent binding → subscription manage → BYO AI settings → about/legal | Profile edits, API keys | Update profile regenerates plan; keychain stores API keys (never uploaded, never CloudKit) | Updated profile, paywall, AI settings | SwiftData + Keychain | All 4 tabs reachable; version read from Bundle.main.infoDictionary (never hardcoded) |
| 15 | Subscription (RevenueCat + StoreKit 2) | 1. Paywall (from any locked feature) → 2. Monthly $7.99 / Annual $49.99 (default selected, 7-day trial) → 3. Purchase → 4. Restore purchases | Product selection | RevenueCat entitlement check; pro unlocks: full plan library, weather adaptation, all events PR, parent report, meet checklist, watermark-free PR card, 8 GLM runs/mo, unlimited Apple AI | Entitlement state across app | RevenueCat + StoreKit 2 | Paywall has Privacy Policy + Terms links + auto-renew disclosure; restore works; annual pre-selected |
| 16 | BYO AI keys | 1. Me → AI Settings → 2. Pick provider (GLM/OpenAI/Claude/Gemini/DeepSeek/custom) → 3. Paste key → 4. Test connection | Provider, endpoint, model, key | Validate via test call; store in Keychain; unlock unlimited AI features | Provider status badge | Keychain only | 6 provider presets + custom; keys never in UserDefaults/CloudKit/logs; BYO overrides quotas |
| 17 | Daily notification | Automatic | Local notification schedule | Morning push: today's plan summary with weather note ("84°F hot — intensity capped at RPE 7") | Local notification | UNUserNotificationCenter | Fires daily at user-chosen morning time; text reflects adaptive plan |
| 18 | HealthKit (optional read-only) | 1. Onboarding/settings optional toggle → 2. Read auth → resting HR/sleep displayed in Me | HKQuantityType read-only | Query recent samples; display only; never uploaded to shared zone | Health snapshot rows | Not persisted (or SwiftData cache, private DB only) | Read-only permission string; no write; excluded from CKShare zone |
| 19 | Multi-device sync | Automatic | All SwiftData models | CloudKit private DB sync; conflict resolution: newest modification + field merge; PR takes better value | Same data on all devices | CloudKit | Offline-first: full functionality without network; sync resumes transparently |
| 20 | Compliance chrome | Automatic | — | Footer on all guidance screens: "For training guidance only. Not medical advice."; red-flag copy defers to school/district policy | Footer text | Static | Present on every training/AI screen; no social features, no contact collection, no UGC |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|--------------------|
| 2.1 | Today tab | Scoreboard typography | Marks/paces in `.monospacedDigit()` oversized type | Static styling |
| 2.2 | Today tab | Weather rationale line | One-line NATA basis under adjusted plan ("Speed session moved to 7 AM — NATA Orange Flag") | Inline caption |
| 4.1 | Weather adaptive | Parent red-flag push | Red/black flag → local push to parent device: "Outdoor practice suspended" | Notification |
| 5.1 | Workout player | Idle timer | `isIdleTimerDisabled = true` during session | Automatic |
| 5.2 | Workout player | Haptics | Start/complete/PR = 3 escalating intensities | Haptic feedback |
| 7.1 | PR celebration | Improvement delta | "+0.24s" / "+0.15m" on card | Computed |
| 9.1 | Plan tab | Phase badge | Base/Build/Peak/Taper chip on week header | Static |
| 10.1 | Parent report | Zero-setup parent | Parent onboarding = scan/code entry only; no profile creation | Invite code flow |
| 12.1 | Form diagnosis | Annotated frame images | Skeleton overlay drawn on frames before upload | Automatic |
| 12.2 | Form diagnosis | Result caching | Same frame-feature hash → cached result, no double billing | Automatic |
| 14.1 | Me | Version display | Reads CFBundleShortVersionString dynamically | Automatic |
| 15.1 | Subscription | Transparent pricing | Monthly and annual side by side, annual default | Paywall layout |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Profile → Plan | Onboarding | PlanEngine/Plan tab | eventGroup, level, goalRace, raceDate | Onboarding complete or profile edit |
| Weather → Today | WBGT engine | Today card + Plan rewrite | HeatFlag, WBGT value | Today view load / app foreground |
| PR → Pace | PersonalRecord | PlanEngine target paces | Best PR per distance | Plan (re)generation |
| Log → Streak | WorkoutSession | StreakState | Completion date | Workout logged |
| Log → PR detect | WorkoutSession (actual mark) | PR celebration | New mark vs existing PR | Log with mark entered |
| Streak + PR → Parent report | StreakState, PersonalRecord, WorkoutSession | WeeklyReport | Weekly aggregates | Sunday 7PM / report generation |
| Entitlement → Features | RevenueCat | All gated features | isPro, glmQuotaUsed, hasBYOKey | App launch / purchase |
| HeatFlag red/black → Parent push | WBGT engine | Notifications | Flag level | Red/black classification |
| daysToRace → Taper | AthleteProfile.raceDate | PlanAdjustmentEngine | days ≤ 7 | Plan load |

**VERIFICATION**: Chinese guide's feature table (2.2) lists 11 rows + onboarding + workout player + notifications + HealthKit + sync = 20 primary features. ✅ Match.

## Apple Design Guidelines Compliance

- **Navigation**: 4-tab bottom bar (Today / Plan / PRs / Me) — standard TabView, Today is default tab
- **Typography**: SF Pro; `largeTitle` × 1.5 for scoreboard headers; `.monospacedDigit()` for all marks/paces
- **Dark mode first**: near-black `#0B0F14` base; semantic heat colors double as UI accent system
- **Touch targets**: ≥ 44pt; single primary capsule CTA per screen
- **Haptics**: UINotificationFeedbackGenerator (success) for PR; UIImpactFeedbackGenerator for set transitions
- **Privacy**: purpose strings explain "why" inline before system dialogs; no data collection beyond CloudKit private DB
- **Kids/teen safety**: 13+, no social, no chat, no UGC, no contact collection
- **Dynamic Type**: all text supports scaling; scoreboard numerals scale but clamp for layout safety

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (Default Free AI Backend)
AI coach Q&A and weekly summary use Apple Intelligence (on-device Foundation Models) as the default backend on iOS 26+; works immediately with zero configuration for reviewers on iPhone 15 Pro+.

**iOS Version Handling**:
- **iOS 26+**: Apple Intelligence default. AI Q&A works out-of-the-box.
- **iOS < 26**: Falls back to BYO API key mode or local template engine. UI: "Apple Intelligence requires iOS 26+. You can add your own AI key in Settings." — never a dead end.
- **Simulator**: Apple Intelligence unavailable → test with BYO key.

### GLM Vision (Form Diagnosis) via Cloudflare Worker
- Client NEVER calls `api.z.ai` directly and NEVER holds a GLM key. All calls go through the shared worker (`cramjam-api.calcs.top` pattern per glm-api-config skill); the app's real Bundle ID is registered in the worker D1 whitelist.
- Quota: free 1/week, Pro 8/month, BYO key unlimited. Quota exhaustion → upsell, never an error.
- Fallback chain: GLM timeout/failure → on-device skeleton feature report (knee angle / trunk lean / contact time). Never a spinner with no response.

### Guideline 2.1(a) — App Completeness
1. Create `app_review_info.md` with demo instructions for reviewers
2. No clickable AI buttons that error without backend
3. BYO key path fully functional as reviewer alternative

### Dead Code Prevention
- ❌ NEVER: `freeGenerationsUsed`, `maxFreeGenerations`, `canGenerateFree`, `incrementGenerationCount()` for Apple-AI-backed features
- Apple AI unlimited for Pro; GLM metered by explicit quota (this is a real consumable, allowed)

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information
Paywall MUST include:
- Functional Privacy Policy link
- Functional Terms of Use (EULA) link
- Subscription title, length, price ($7.99/month; $49.99/year with 7-day free trial)
- Auto-renewal disclosure text

### BYO Key + Subscription Model
- Subscription value: "Unlock PRDay Pro — full plans, weather adaptation, parent reports" — NOT "Unlimited AI"
- Paywall feature list leads with app features
- AI generation unlimited for BYO key users regardless of subscription

## Technical Architecture

- **Language**: Swift 5.9+, Swift 6 concurrency where safe
- **UI**: SwiftUI (100%), Swift Charts
- **Data**: SwiftData (local-first, single source of truth) + CloudKit private DB sync + CKShare (parent read-only)
- **Weather**: WeatherKit → local WBGTEngine (pure functions, unit-tested)
- **Notifications**: UNUserNotificationCenter (daily plan push, Sunday 7PM report push, red-flag parent alert)
- **Health**: HealthKit read-only (optional)
- **Pose**: Vision (VNDetectHumanBodyPoseRequest) + AVFoundation frame extraction
- **AI**: FoundationModels (iOS 26+ on-device) → AICoachRouter → GLM-5.3-Flash via Cloudflare Worker (OpenAI-compatible) → local template fallback. BYO multi-provider client (GLM/OpenAI/Claude/Gemini/DeepSeek/custom).
- **IAP**: StoreKit 2 + RevenueCat
- **Zero third-party UI/network deps**: charts native, networking URLSession

### Implementation rules (from guide, mandatory)
1. **Local-first**: SwiftData is the only source of truth; CloudKit syncs. Full functionality offline.
2. **Engines are pure**: PlanEngine / WBGTEngine / PaceEngine / StreakEngine are UI-free structs/enums, unit-testable.
3. **Idiot-proofing**: streaks fixable only via makeup flow, never auto-reset; AI always has fallback; all writes idempotent (clientUUID upsert).
4. **Teen compliance**: no contact collection, no social feed, health data in iCloud private DB only; footer disclaimer everywhere.

## Module Structure

```
PRDay/
├── PRDayApp.swift                 // Entry, model container, notification setup
├── Models/
│   ├── AthleteProfile.swift       // eventGroup, level, goalRace, raceDate
│   ├── WorkoutSession.swift       // clientUUID unique, rpe, wbgt snapshot
│   ├── PersonalRecord.swift       // event, mark, windAssisted
│   ├── StreakState.swift          // versioned, append-only events
│   ├── StreakEvent.swift
│   ├── WeeklyReport.swift         // snapshot
│   ├── MeetChecklistState.swift
│   └── Enums.swift                // EventGroup, Level, HeatFlag, PlanPhase
├── Engines/
│   ├── PlanEngine.swift           // 4 groups × levels × phases plan generation
│   ├── PlanLibrary.swift          // workout templates data
│   ├── WBGTEngine.swift           // compute + NATA classify
│   ├── PlanAdjustmentEngine.swift // heat rewrite + taper
│   ├── PaceEngine.swift           // Riegel + VDOT + E/M/T/I/R zones
│   └── StreakEngine.swift         // versioned streak calc + makeup
├── Services/
│   ├── WeatherService.swift       // WeatherKit + cache + degradation
│   ├── NotificationService.swift  // daily/sunday/red-flag
│   ├── HealthKitService.swift
│   ├── CloudSyncService.swift     // SwiftData+CloudKit, CKShare parent
│   ├── ParentReportService.swift  // aggregate + render report card
│   ├── SubscriptionService.swift  // RevenueCat/StoreKit2 wrapper
│   ├── KeychainStore.swift
│   └── LLMClient.swift            // OpenAI-compatible client (BYO)
├── AI/
│   ├── AICoachRouter.swift        // task × entitlement → backend
│   ├── AppleIntelligenceService.swift // FoundationModels (iOS 26+)
│   ├── FormAnalyzer.swift         // Vision pose extraction
│   ├── FormDiagnosisService.swift // worker call + fallback report
│   └── TemplateCoach.swift        // local fallback engine
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── TodayViewModel.swift
│   ├── WorkoutPlayerViewModel.swift
│   ├── PlanViewModel.swift
│   ├── PRsViewModel.swift
│   ├── MeViewModel.swift
│   └── PaywallViewModel.swift
├── Views/
│   ├── Onboarding/
│   ├── Today/                     // TodayView, HeatFlagCard, WorkoutPlayerView
│   ├── Plan/                      // WeekView, DayDetail, MeetChecklist
│   ├── PRs/                       // TimelineView, PBChartView, CelebrationView, ShareCard
│   ├── Me/                        // Profile, FamilySharing, AISettings, About
│   ├── Paywall/
│   └── Components/                // ScoreboardNumber, FlagChip, PrimaryButton
└── Resources/
```

## ⚠️ Data Flow Diagram (MANDATORY — Key Features)

```
Feature: Today Workout (core loop)
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Open app / pull to refresh                           │
│       │                                                   │
│  ViewModel: TodayViewModel                                │
│  └── load() → WeatherService.current() → WBGTEngine       │
│      → HeatFlag → PlanAdjustmentEngine.adjust(todayPlan)  │
│      → cache adjusted PlanDay                             │
│       │                                                   │
│  Model/Persistence                                        │
│  └── SwiftData: PlanDay (adjusted), WeatherCache          │
│       │                                                   │
│  Display Output                                           │
│  └── TodayView: card #1 = workout, chip = flag color,     │
│      rationale caption, Start button                      │
│       │                                                   │
│  Cross-Feature Output                                     │
│  └── Start → WorkoutPlayer; red/black → parent push       │
└───────────────────────────────────────────────────────────┘

Feature: Workout Log (idempotent)
┌───────────────────────────────────────────────────────────┐
│  User Input → RPE slider (1-10), optional mark, Log tap   │
│  VM: WorkoutPlayerViewModel.log()                         │
│      → clientUUID = UUID (stable per planDay+date)        │
│      → upsert WorkoutSession (unique attribute)           │
│      → StreakEngine.record(date) → versioned StreakState  │
│      → if mark: PR detect → CelebrationView or progress   │
│  Persistence: WorkoutSession, StreakEvent (append-only)   │
│  Output: streak flame +1, PR confetti OR "1.2s to PR"     │
└───────────────────────────────────────────────────────────┘

Feature: Parent Weekly Report
┌───────────────────────────────────────────────────────────┐
│  Trigger: Sunday 19:00 local notification / manual        │
│  VM: ParentReportService.build()                          │
│      → query week's WorkoutSessions + PRs + StreakState   │
│      → completion %, new PRs, next-week focus             │
│      → render 9:16 report card image                      │
│  Persistence: WeeklyReport snapshot → CloudKit shared zone│
│  Output: parent device push → read-only report card view  │
│  Constraint: heart-rate details NEVER enter shared zone   │
└───────────────────────────────────────────────────────────┘

Feature: AI Form Diagnosis
┌───────────────────────────────────────────────────────────┐
│  Input: video (≤10s) → FormAnalyzer.extractFrames()       │
│  Processing: Vision pose per 0.5s × 6s → PoseFeatures     │
│      → annotated JPEG frames → hash cache check           │
│      → quota check (free 1/wk, Pro 8/mo, BYO ∞)           │
│      → Worker POST (OpenAI-compatible chat, images)       │
│  Fallback: GLM fail → on-device feature report (instant)  │
│  Persistence: report text only; video/frames deleted      │
│  Output: diagnosis card (3 strengths, 3 fixes, safety)    │
└───────────────────────────────────────────────────────────┘
```

## Implementation Flow

1. Project skeleton: xcodegen project.yml, SwiftUI app, SwiftData container, 4 tabs, dark theme
2. Models + Enums (all 8 SwiftData models with CloudKit-compatible optionals)
3. Engines: WBGTEngine → PaceEngine → PlanEngine/PlanLibrary → PlanAdjustmentEngine → StreakEngine (each with unit tests)
4. Today tab: TodayViewModel + WeatherService + heat flag UI + workout card
5. Workout player: timer state machine, idle timer, haptics, idempotent log
6. PRs tab: record CRUD, timeline, Swift Charts PB curve, celebration + share card
7. Streak UI + makeup repair flow
8. Plan tab: week view, day detail, meet-day checklist
9. Onboarding: role → group → level → permissions → first plan
10. CloudKit sync + CKShare parent sharing + ParentReportService + notifications
11. AI layer: FormAnalyzer (Vision), AICoachRouter, AppleIntelligenceService, LLMClient, FormDiagnosisService, TemplateCoach fallback
12. RevenueCat + Paywall (legal links, auto-renew text, transparent pricing)
13. BYO AI settings (6 providers + custom, Keychain)
14. Settings/Me, about, disclaimer footers, version display
15. Full build verification iPhone + iPad simulators

## UI/UX Design Specifications

- **Palette**: base `#0B0F14`, surface `#141A22`, primary electric orange `#FF6B2C` (brand), heat semantic: green `#34C759` / yellow `#FFD60A` / orange `#FF9F0A` / red `#FF3B30` / black `#1C1C1E`; parent report view: white cards, soft shadow, minimal
- **Typography**: SF Pro; hero numerals 64-96pt monospacedDigit; titles largeTitle ×1.5 bold; captions .footnote secondary
- **Layout**: single-column; today card pinned first; 44pt min targets; one capsule CTA per screen
- **Animations**: PR = full-screen confetti (Canvas/TimelineView) 60fps + heavy haptic; streak flame pulse; flag color transitions
- **Workout mode**: `isIdleTimerDisabled`, 1-second countdown ring, current set at 80pt
- **Parent report**: 9:16 renderable card (ImageRenderer), IG/SMS optimized

## Code Generation Rules

- One feature per module, high cohesion, low coupling
- Semantic naming; no comments unless logic is non-obvious
- Apple-native first; zero third-party dependencies except RevenueCat
- Open-source references (MIT/Apache, may adapt): apple/sample-cloudkit-sharing, apple/sample-cloudkit-sync-engine, StanfordBDHG/HealthGPT, RevenueCat/purchases-ios, OpenTracksApp/OpenTracks (data model only), google-ai-edge/mediapipe (optional). GPL/AGPL/unlicensed (wger, Runalyze, GoldenCheetah, pywbgt): algorithm concepts only, NEVER copy code.
- GLM integration: via Cloudflare Worker proxy only (glm-api-config skill standard, repo asunnyboy861/GLM-Cloudflare); never direct api.z.ai from app; never ship GLM keys in app
- Version via `Bundle.main.infoDictionary` only

## Build & Deployment Checklist

1. xcodegen project.yml (App target, DEVELOPMENT_TEAM = JP4TN5PTS3, bundle `com.zzoutuo.PRDay`, iOS 17.0)
2. Capabilities: iCloud (CloudKit, container), Push Notifications, Background Modes (remote-notification), WeatherKit, HealthKit (optional read)
3. App icon 1024px (Agnes Image API primary)
4. PrivacyInfo.xcprivacy + usage strings (camera, health, location-when-in-use for weather, notifications)
5. Build & run: iPhone + iPad simulators
6. Unit tests: WBGTEngine (5 flags), PaceEngine (Riegel/VDOT), StreakEngine (no-reset), PlanEngine (4 groups)
7. RevenueCat products: `pro_monthly_799`, `pro_annual_4999` (7-day trial on annual)
8. Export compliance: standard encryption exemption
