import Foundation

@MainActor
final class AIProfileManager: ObservableObject {
    static let shared = AIProfileManager()

    @Published var activeProviderID: String? {
        didSet { AIConfiguration.activeProviderID = activeProviderID }
    }
    @Published var customEndpoint: String
    @Published var customModel: String

    init() {
        activeProviderID = AIConfiguration.activeProviderID
        customEndpoint = UserDefaults.standard.string(forKey: "ai.customEndpoint") ?? ""
        customModel = UserDefaults.standard.string(forKey: "ai.customModel") ?? ""
    }

    var activeProvider: AIProvider? {
        guard let id = activeProviderID else { return nil }
        return AIProviderCatalog.provider(id: id)
    }

    var hasActiveKey: Bool {
        guard let id = activeProviderID else { return false }
        return !(AIConfiguration.apiKey(for: id) ?? "").isEmpty
    }

    var hasAnyKey: Bool {
        AIConfiguration.hasAnyProviderKey
    }

    var effectiveModel: String {
        guard let provider = activeProvider else { return "" }
        return provider.id == "custom" ? customModel : provider.defaultModel
    }

    var effectiveEndpoint: String {
        guard let provider = activeProvider else { return "" }
        return provider.id == "custom" ? customEndpoint : provider.endpoint
    }

    func activate(providerID: String) {
        activeProviderID = providerID
    }

    func saveKey(_ key: String, for providerID: String) {
        AIConfiguration.saveApiKey(key, providerID: providerID)
        activeProviderID = providerID
    }

    func removeKey(for providerID: String) {
        AIConfiguration.deleteApiKey(providerID: providerID)
        if activeProviderID == providerID {
            activeProviderID = nil
        }
    }

    func saveCustom(endpoint: String, model: String) {
        customEndpoint = endpoint
        customModel = model
        UserDefaults.standard.set(endpoint, forKey: "ai.customEndpoint")
        UserDefaults.standard.set(model, forKey: "ai.customModel")
    }

    func makeActiveService() -> (any AIService)? {
        guard let provider = activeProvider, hasActiveKey else { return nil }
        let key = AIConfiguration.apiKey(for: provider.id) ?? ""
        if provider.id == "custom" {
            let custom = AIProviderCatalog.custom
            return BYOProviderService(provider: AIProvider(id: custom.id, label: custom.label, endpoint: customEndpoint, defaultModel: customModel, supportsVision: true), apiKey: key, model: customModel)
        }
        return BYOProviderService(provider: provider, apiKey: key, model: provider.defaultModel)
    }

    func testConnection() async throws -> String {
        guard let service = makeActiveService() else {
            throw AIServiceError(message: "Add an API key first.")
        }
        return try await service.chat(system: "You are a connection tester. Reply with exactly: OK", user: "ping", imagesJPEGBase64: [])
    }
}
