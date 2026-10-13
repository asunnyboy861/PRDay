import Foundation

struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}

struct BYOProviderService: AIService {
    let provider: AIProvider
    let apiKey: String
    let model: String

    var supportsVision: Bool { provider.supportsVision }

    func chat(system: String, user: String, imagesJPEGBase64: [String]) async throws -> String {
        guard !provider.endpoint.isEmpty else {
            throw AIServiceError(message: "No endpoint configured for this provider.")
        }
        var content: [[String: Any]] = []
        if !imagesJPEGBase64.isEmpty && provider.supportsVision {
            content.append(["type": "text", "text": user])
            for b64 in imagesJPEGBase64 {
                content.append(["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]])
            }
        } else {
            content.append(["type": "text", "text": user])
        }
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": content]
            ]
        ]
        var request = URLRequest(url: URL(string: "\(provider.endpoint)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 90
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Request failed"
            throw AIServiceError(message: "Provider error (\(http.statusCode)): \(message.prefix(200))")
        }
        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content else {
            throw AIServiceError(message: "Empty response from provider.")
        }
        return text
    }
}
