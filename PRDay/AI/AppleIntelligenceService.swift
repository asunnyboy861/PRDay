import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
@available(iOS 26.0, *)
enum AppleIntelligenceService {
    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    static func chat(system: String, user: String) async throws -> String {
        let instructions: String? = system.isEmpty ? nil : system
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: user)
        return response.content
    }
}
#endif

enum AppleIntelligenceGate {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return AppleIntelligenceService.isAvailable
        }
        #endif
        return false
    }
}
