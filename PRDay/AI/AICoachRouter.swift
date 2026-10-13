import Foundation

enum AICoachRouter {
    enum Task {
        case chatQA
        case weeklySummary
        case formDiagnosis
        case planTweak
    }

    enum Backend {
        case appleOnDevice
        case byoProvider(any AIService)
        case glmProxy
        case template
        case upsell
    }

    @MainActor
    static func route(_ task: Task, isPro: Bool, profiles: AIProfileManager) -> Backend {
        switch task {
        case .chatQA, .weeklySummary:
            if AppleIntelligenceGate.isAvailable {
                return .appleOnDevice
            }
            if profiles.hasAnyKey, let service = profiles.makeActiveService() {
                return .byoProvider(service)
            }
            return .template
        case .formDiagnosis, .planTweak:
            if profiles.hasAnyKey, let service = profiles.makeActiveService() {
                return .byoProvider(service)
            }
            if GLMProxyService.isConfigured {
                return .glmProxy
            }
            if task == .formDiagnosis {
                return .template
            }
            return .upsell
        }
    }
}

@MainActor
enum Entitlement {
    static var glmFreeWeeklyQuota: Int { 1 }
    static var glmProMonthlyQuota: Int { 8 }

    static func glmQuota(isPro: Bool) -> (limit: Int, period: String) {
        isPro ? (glmProMonthlyQuota, "month") : (glmFreeWeeklyQuota, "week")
    }

    static func glmUsedThisPeriod(isPro: Bool) -> Int {
        let key = Self.glmUsageKey(isPro: isPro)
        return UserDefaults.standard.integer(forKey: key)
    }

    static func canRunGLM(isPro: Bool) -> Bool {
        if AIConfiguration.hasAnyProviderKey { return true }
        let (limit, _) = glmQuota(isPro: isPro)
        return glmUsedThisPeriod(isPro: isPro) < limit
    }

    static func recordGLMRun(isPro: Bool) {
        let key = Self.glmUsageKey(isPro: isPro)
        UserDefaults.standard.set(glmUsedThisPeriod(isPro: isPro) + 1, forKey: key)
    }

    private static func glmUsageKey(isPro: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = isPro ? "yyyy-MM" : "yyyy-'W'ww"
        return "glm.used.\(formatter.string(from: Date.now))"
    }
}
