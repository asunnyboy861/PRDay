# Pricing Configuration

## Monetization Model: Subscription (IAP)

Free download with a free tier; PRDay Pro auto-renewable subscription ($7.99/month or $49.99/year, 7-day free trial, annual pre-selected). No lifetime/buyout products — GLM vision API is a consumable cost, so AI form diagnosis is quota-based for Pro and unlimited only via BYO API key. Apple on-device AI (cost-free) is unlimited for Pro.

## Subscription Group
- **Group Name**: PRDay Pro
- **Reference Name**: PRDay Pro
- **Products in group**: Monthly subscription, Yearly subscription (both auto-renewable)

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: PRDay Pro Monthly
- **Product ID**: `com.zzoutuo.PRDay.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $7.99 USD per month
- **Display Name**: `PRDay Pro Monthly` (17 chars, ≤35 ✅)
- **Description**: `Adaptive plans, parent reports, all PR tools` (45 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: PRDay Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription
- **Reference Name**: PRDay Pro Annual
- **Product ID**: `com.zzoutuo.PRDay.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $49.99 USD per year (48% savings vs monthly)
- **Display Name**: `PRDay Pro Annual` (16 chars, ≤35 ✅)
- **Description**: `A full year of adaptive training and reports` (44 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: PRDay Pro (same group as monthly)
- **Restore Purchases**: ✅ Required
- **Note**: Annual is the default-selected option on the Paywall (transparent side-by-side pricing with monthly; no dark patterns)

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - Today workout: 1 recommended workout per day + logging
  - WBGT heat-risk flag (see today's flag and NATA rule)
  - PR tracking for first 3 events
  - Streak counter (never silently resets)
  - PR celebration card (with PRDay watermark)
  - AI coach Q&A: unlimited (Apple on-device, zero cost)
  - AI form diagnosis: 1/week (GLM via worker, metered hook)
- **Conversion hooks**:
  - Second weekly AI form check reaches the Pro wall (experience the difference first)
  - Weather-adaptive plan rewriting is a Pro feature — free users see the flag but the plan stays stock
  - Parent weekly report + family sharing is Pro-only (parents are the paying decision-makers)
  - Full plan library (4 event groups × 12-16 weeks) locked; free gets today's pick only
  - Meet-day checklist locked
  - Watermark removal on PR share cards

## Pro Features Unlocked (All Paid Tiers)

Cross-referenced with capabilities.md: CloudKit ✅ configured, Push ✅ configured, GLM via Cloudflare Worker (worker-side quota, registered via glm-api-config), all features local-first SwiftData.

| Feature | Free | Pro (All Paid Tiers) |
|---------|:----:|:--------------------:|
| Today workout (1/day recommendation) | ✅ | ✅ Full plan library (4 event groups × 12-16 week periodized) |
| WBGT heat-risk flag | ✅ | ✅ + weather-adaptive plan rewriting |
| PR tracking | First 3 events | All events |
| Streak counter | ✅ | ✅ |
| PR celebration card | Watermarked | No watermark + custom |
| AI coach Q&A (Apple on-device) | Unlimited | Unlimited |
| AI form diagnosis (GLM vision via worker) | 1/week | 8/month quota |
| AI form diagnosis (BYO API key configured) | Unlimited | Unlimited (own key overrides quota) |
| Parent weekly report + CloudKit family sharing | ❌ | ✅ |
| Meet-day checklist | ❌ | ✅ |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid subscription; cancel anytime before renewal)
- **Available for**: Both monthly and yearly tiers (yearly pre-selected on Paywall)

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView ($7.99/month, $49.99/year, annual default, 7-day trial)
- [x] Free trial terms included
- [x] Restore purchases functionality implemented
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] BYO Key model: AI generation unlimited with user's own key; subscription sells app features (plans, parent reports, adaptation), never "unlimited AI" as primary value; no free-generation counting for Apple-AI-backed features (`canGenerate` = `isPremium || hasAPIKey || appleIntelligenceAvailable`)
- [x] GLM metered quota (free 1/week, Pro 8/month) is a real consumable cost — allowed; quota exhaustion routes to upsell, never an error state
