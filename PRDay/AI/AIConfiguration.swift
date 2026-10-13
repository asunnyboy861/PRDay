import Foundation

struct AIProvider: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var endpoint: String
    var defaultModel: String
    var supportsVision: Bool
}

enum AIProviderCatalog {
    static let builtin: [AIProvider] = [
        AIProvider(id: "glm", label: "GLM", endpoint: "https://api.z.ai/api/paas/v4", defaultModel: "glm-5.3-flash", supportsVision: true),
        AIProvider(id: "openai", label: "OpenAI", endpoint: "https://api.openai.com/v1", defaultModel: "gpt-4o-mini", supportsVision: true),
        AIProvider(id: "claude", label: "Claude", endpoint: "https://api.anthropic.com/v1", defaultModel: "claude-sonnet", supportsVision: true),
        AIProvider(id: "gemini", label: "Gemini", endpoint: "https://generativelanguage.googleapis.com/v1beta/openai", defaultModel: "gemini-2.0-flash", supportsVision: true),
        AIProvider(id: "deepseek", label: "DeepSeek", endpoint: "https://api.deepseek.com/v1", defaultModel: "deepseek-chat", supportsVision: false)
    ]

    static let custom = AIProvider(id: "custom", label: "Custom", endpoint: "", defaultModel: "", supportsVision: true)

    static var all: [AIProvider] { builtin + [custom] }

    static func provider(id: String) -> AIProvider? {
        all.first { $0.id == id }
    }
}

enum AIConfiguration {
    static let keychainService = "com.zzoutuo.PRDay.ai"

    static func apiKey(for providerID: String) -> String? {
        KeychainHelper.readString(service: keychainService, account: "key-\(providerID)")
    }

    static func saveApiKey(_ key: String, providerID: String) {
        KeychainHelper.saveString(key, service: keychainService, account: "key-\(providerID)")
    }

    static func deleteApiKey(providerID: String) {
        KeychainHelper.delete(service: keychainService, account: "key-\(providerID)")
    }

    static var hasAnyProviderKey: Bool {
        AIProviderCatalog.all.contains { !(apiKey(for: $0.id) ?? "").isEmpty }
    }

    static var activeProviderID: String? {
        get { UserDefaults.standard.string(forKey: "ai.activeProvider") }
        set { UserDefaults.standard.set(newValue, forKey: "ai.activeProvider") }
    }

    static var appleIntelligenceAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return AppleIntelligenceService.isAvailable
        }
        #endif
        return false
    }
}
