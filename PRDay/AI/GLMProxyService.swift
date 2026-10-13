import Foundation
import StoreKit

enum GLMError: LocalizedError {
    case proxyNotConfigured
    case rateLimited
    case badResponse
    case emptyContent
    case receiptRejected

    var errorDescription: String? {
        switch self {
        case .proxyNotConfigured: return "Cloud AI is being set up. Add your own API key in Me → AI Settings for unlimited use."
        case .rateLimited: return "Too many cloud requests right now. Please try again later."
        case .badResponse: return "Cloud service error. Try again later."
        case .emptyContent: return "Cloud returned no result. Try again."
        case .receiptRejected: return "This is a Pro feature. Restore your purchase or subscribe to continue."
        }
    }
}

final class GLMProxyService: AIService, @unchecked Sendable {
    static let shared = GLMProxyService()

    private let proxyURL = URL(string: "https://cramjam-api.calcs.top")!
    private let proxyFallbackURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!
    private let model = "glm-5.3-flash"
    private let appId = "prday"
    private let keychainService = "com.zzoutuo.PRDay.ai"

    static var isConfigured: Bool {
        shared.proxyDevKey != nil
    }

    var supportsVision: Bool { true }

    private var proxyDevKey: String? {
        guard let url = Bundle.main.url(forResource: "GLMProxySecret", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }

    private var userID: String {
        if let existing = KeychainHelper.readString(service: keychainService, account: "glm.proxy.user") {
            return existing
        }
        let id = UUID().uuidString
        KeychainHelper.saveString(id, service: keychainService, account: "glm.proxy.user")
        return id
    }

    private func currentEntitlementJWS() async -> String? {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  transaction.productType == .autoRenewable else { continue }
            let jws = result.jwsRepresentation
            if !jws.isEmpty {
                return jws
            }
        }
        return nil
    }

    func chat(system: String, user: String, imagesJPEGBase64: [String]) async throws -> String {
        var userContent: [[String: Any]] = [["type": "text", "text": user]]
        for b64 in imagesJPEGBase64 {
            userContent.append(["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]])
        }
        let messages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": userContent]
        ]
        let payload: [String: Any] = [
            "model": model,
            "messages": messages,
            "thinking": ["level": "low"],
            "max_tokens": 8192
        ]
        var body: [String: Any] = [
            "appId": appId,
            "userId": userID,
            "payload": payload
        ]
        if let jws = await currentEntitlementJWS() {
            body["appTransaction"] = jws
        } else if let devKey = proxyDevKey {
            body["devKey"] = devKey
        } else {
            throw GLMError.proxyNotConfigured
        }
        return try await sendWithFallback(payload: body)
    }

    private func sendWithFallback(payload: [String: Any]) async throws -> String {
        do {
            return try await send(url: proxyURL, payload: payload)
        } catch GLMError.badResponse, GLMError.emptyContent {
            return try await send(url: proxyFallbackURL, payload: payload)
        }
    }

    private func send(url: URL, payload: [String: Any]) async throws -> String {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw GLMError.badResponse }
        switch http.statusCode {
        case 200:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String, !content.isEmpty else {
                throw GLMError.emptyContent
            }
            return content
        case 401:
            throw GLMError.receiptRejected
        case 429:
            throw GLMError.rateLimited
        default:
            throw GLMError.badResponse
        }
    }
}
