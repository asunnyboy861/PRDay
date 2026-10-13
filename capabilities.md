# Capabilities Configuration

## Analysis
Based on operation guide + us.md analysis:
- "CloudKit (sync + CKShare family sharing)" → iCloud / CloudKit — detected ("sync", "CloudKit", "CKShare", "family")
- "Sunday 7PM push / daily morning push / red-flag parent push" → Push Notifications — detected ("notification", "push")
- "WeatherKit" → WeatherKit App ID service — detected
- "HealthKit (optional read-only heart rate / sleep)" → HealthKit — detected ("health")
- "Background remote-notification for report sync" → Background Modes — detected ("background")
- "Camera for form videos" → Camera usage string — detected
- "Location for local weather" → Location When-In-Use usage string — detected
- "RevenueCat + StoreKit 2 subscriptions" → In-App Purchase (default, no entitlement file needed)
- No Watch app, no Widgets, no App Groups required by guide

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| iCloud / CloudKit (container `iCloud.com.zzoutuo.PRDay`) | ✅ Configured & portal-registered | entitlements in project.yml target + Xcode automatic provisioning (-allowProvisioningUpdates) |
| Push Notifications (aps-environment) | ✅ Configured & portal-registered | entitlements + automatic provisioning |
| HealthKit | ✅ Configured & portal-registered | entitlements + automatic provisioning |
| Background Modes (remote-notification) | ✅ Configured | Info.plist UIBackgroundModes |
| WeatherKit | ✅ Auto-registered via App ID service during provisioning | automatic signing |
| Camera / Location / Health usage strings | ✅ Configured | Info.plist (xcodegen info.properties) |
| In-App Purchase | ✅ Default capability | no action needed |
| PrivacyInfo.xcprivacy (UserDefaults CA92.1 + FileTimestamp C617.1) | ✅ Configured | App target source folder |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| CloudKit Schema deployment (Development → Production) | ⏳ After first device run with iCloud signed-in, or via CloudKit Dashboard | PHASE 8.5 will list exact steps; app gracefully degrades to local-only SwiftData until then |
| RevenueCat account + products (pro_monthly_799 / pro_annual_4999) | ⏳ PHASE 3/4 will create product config in code; ASC products created during metadata phase | App degrades to local entitlement if RC unavailable |

## No Configuration Needed
- App Groups (no extensions), Apple Watch (not in guide), Siri, Sign in with Apple (not in guide)

## Verification
- Build succeeded after configuration (simulator): ✅ BUILD SUCCEEDED
- Device signing verification (generic/platform=iOS, -allowProvisioningUpdates): ✅ PASSED — real signing identity, entitlements embedded
- Signed entitlements verified: aps-environment=development ✅, healthkit ✅, icloud-container-identifiers=iCloud.com.zzoutuo.PRDay (Dev+Prod) ✅, icloud-services=* ✅, team-identifier=JP4TN5PTS3 ✅
- DEVELOPMENT_TEAM: JP4TN5PTS3 baked at project level (all targets inherit)
- PrivacyInfo.xcprivacy: App target covered (single-target app)
- Signing mode: fully automatic; no DEFERRED state — Xcode account auto-registered all capabilities on the portal
