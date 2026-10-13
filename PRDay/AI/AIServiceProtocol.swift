import Foundation

protocol AIService {
    var supportsVision: Bool { get }
    func chat(system: String, user: String, imagesJPEGBase64: [String]) async throws -> String
}

struct AIServiceError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
