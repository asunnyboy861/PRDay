# App Review Information

## Demo Account for Apple Review

### API Key Configuration
The app uses a "Bring Your Own API Key" model for its optional cloud AI. To test AI features without any configuration:
- **No setup is required.** The AI Coach Q&A works out of the box via Apple Intelligence on supported devices (iPhone 15 Pro+, iOS 26+).
- On devices without Apple Intelligence, Ask Coach falls back to an offline template coach — it always answers, never errors.
- AI Form Check always works: it analyzes the video on-device with Vision (skeleton tracking) and produces a report even with no network and no key.

To test cloud AI with your own key:
1. Open Me → AI Settings (BYO Key)
2. Pick a provider (GLM / OpenAI / Claude / Gemini / DeepSeek / Custom), paste an API key, tap "Save Key", then "Test Connection"
3. AI Form Check and Ask Coach now route to that provider with unlimited usage

### HealthKit Integration
HealthKit integration is clearly identified in the app UI:
- Me → "Apple Health (HealthKit)" section with HealthKit icon
- Row labeled "HealthKit Integration" with "Learn More" button opening a dedicated HealthKit info page
- Toggle labeled "Sync Resting Heart Rate from HealthKit"
- Description: "Read resting heart rate from Apple Health via HealthKit"
The app READS resting heart rate only (optional, off by default). No health data is written, and health data is never included in parent family reports.

### WeatherKit Usage (Apple Weather Attribution)
The app uses Apple WeatherKit for local heat-condition (WBGT) training guidance. Apple Weather attribution appears:
- On the Today tab weather card (" Apple Weather" mark + legal link at weather.apple.com/legal)
- In Me → Legal ("Weather — Data Source" link row)
- In the Settings footer ("Weather information provided by Apple Weather.")
- On PR share cards where weather context is drawn

### Subscription Testing
- Product IDs: `com.zzoutuo.PRDay.pro.monthly` ($7.99/month), `com.zzoutuo.PRDay.pro.yearly` ($49.99/year)
- Both tiers: 7-day free trial, auto-renewable, in the "PRDay Pro" subscription group
- Paywall includes Privacy Policy + Terms of Use links and auto-renewal disclosure
- Restore Purchases available on the Paywall and in Me

### Required Links (In-App)
- Privacy Policy: https://asunnyboy861.github.io/PRDay/privacy.html
- Terms of Use: https://asunnyboy861.github.io/PRDay/terms.html
- Support Page: https://asunnyboy861.github.io/PRDay/support.html

These links are accessible from:
1. Me → Legal section
2. Paywall (below the Subscribe button)

## Review Notes

### Teen Safety
- The app is designed for athletes 13+. There is no social feed, no chat between users, no user-generated content sharing, and no contact information collection. The only communication channel is the Contact Support form (goes to the developer).
- All training guidance screens carry the footer: "For training guidance only. Not medical advice."
- Heat guidance follows publicly available NATA/ACSM heat-flag conventions and explicitly defers to school/district policies.

### AI Features (BYO Key Model)
- Apple Intelligence (on-device) is the default AI backend — free, works without any key on supported devices
- Users may optionally bring their own API key (stored in the iOS Keychain only, never uploaded)
- The app does NOT sell API keys or AI usage; no specific provider is promoted in user-facing UI
- AI Form Check consumes server quota only when routed through the developer-hosted proxy: free tier 1/week, Pro 8/month; a user's own key overrides quotas with unlimited use
- All AI features have offline fallbacks (Vision-based on-device analysis, template coach) — no dead-end error states

### China App Store Compliance
This app is distributed on the US storefront only. It does NOT include ChatGPT functionality or reference ChatGPT/OpenAI in any metadata. The AI feature uses a generic "Bring Your Own API Key" model where users configure their own API endpoint from a neutral provider list (provider names shown only as connection presets in Settings). No specific AI provider is promoted or bundled.

### Offline Capability
All core features (plan generation, workout logging, PR tracking, streaks, heat flags from cached weather) work fully offline. Local data is the source of truth; iCloud sync is an enhancement.
