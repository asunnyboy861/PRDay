# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | PRDay |
| **Git URL** | git@github.com:asunnyboy861/PRDay.git |
| **Repo URL** | https://github.com/asunnyboy861/PRDay |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ⏳ Pending (enabled in PHASE 7 from `/docs`) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/PRDay/ | ✅ Active |
| Support | https://asunnyboy861.github.io/PRDay/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/PRDay/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/PRDay/terms.html | ✅ Active |

## Build Verification

| Check | Result |
|-------|--------|
| iPhone 16 (iOS 26.4) build | ✅ BUILD SUCCEEDED |
| iPhone run test | ✅ Launched (PID 6497) |
| iPad Pro 13-inch (M5) build & run | ✅ Launched (PID 7252) |
| Unit tests (27 tests, 6 suites) | ✅ ALL PASSED |
| Release build + secret exclusion | ✅ GLMProxySecret.txt absent from Release bundle |
| Device signing (generic/platform=iOS) | ✅ PASSED (Team JP4TN5PTS3, iCloud/Push/HealthKit portal-registered) |

## Repository Structure

```
PRDay/
├── PRDay.xcodeproj/               # Xcode Project (xcodegen from project.yml)
├── PRDay/                         # Swift Source Files
│   ├── App/                       # Theme.swift
│   ├── Models/                    # SwiftData models (CloudKit-compatible)
│   ├── Engines/                   # WBGTEngine, PaceEngine, PlanEngine, PlanAdjustmentEngine, StreakEngine, PlanLibrary
│   ├── Services/                  # Weather, Notifications, HealthKit, CloudSync (CKShare), ParentReport, Keychain
│   ├── AI/                        # AICoachRouter, AppleIntelligenceService, BYOProviderService, GLMProxyService, FormAnalyzer, FormDiagnosisService, TemplateCoach
│   ├── ViewModels/                # MVVM per module + PurchaseManager (StoreKit 2)
│   ├── Views/                     # Today/Plan/PRs/Me/Paywall/Support + Onboarding
│   └── Assets.xcassets            # App icon (Agnes generated)
├── PRDayTests/                    # 27 unit tests across 6 suites
├── docs/                          # Policy pages (added in PHASE 7)
├── project.yml                    # xcodegen source of truth
├── us.md                          # English development guide
├── capabilities.md                # Capability configuration record
├── icon.md                        # Icon generation record
├── price.md                       # Monetization configuration
├── app_review_info.md             # App Review demo instructions
├── nowgit.md                      # This file
├── .env                           # ⚠️ EXCLUDED (.gitignore — secrets)
├── keytext*.md                    # ⚠️ EXCLUDED (.gitignore — confidential ASO)
├── COMPETITOR_REPORT.md           # ⚠️ EXCLUDED (.gitignore — confidential)
├── app_audit*.md                  # ⚠️ EXCLUDED (.gitignore — internal audit)
└── PRDay/GLMProxySecret.txt       # ⚠️ EXCLUDED (.gitignore + Release EXCLUDED_SOURCE_FILE_NAMES)
```
