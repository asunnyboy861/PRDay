import SwiftUI

struct ContactSupportView: View {
    enum Subject: String, CaseIterable, Identifiable {
        case general = "General"
        case feature = "Feature Suggestion"
        case bug = "Bug Report"
        case usage = "Usage Question"
        case performance = "Performance Issue"
        case ui = "UI Improvement"
        case other = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "bubble.left.fill"
            case .feature: return "lightbulb.fill"
            case .bug: return "ant.fill"
            case .usage: return "questionmark.circle.fill"
            case .performance: return "gauge.with.dots.needle.67percent"
            case .ui: return "paintpalette.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }

    @State private var subject: Subject = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var resultText: String?
    @State private var isSuccess = false

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".") && email.count > 4
    }

    private var canSubmit: Bool {
        !name.isEmpty && isEmailValid && !message.isEmpty && message.count <= 1000 &&
            (subject != .other || !customSubject.isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What's it about?")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach([Subject.general, .feature, .bug, .usage, .performance, .ui]) { s in
                        tile(s)
                    }
                }
                tile(.other)
                if subject == .other {
                    TextField("Tell us the topic…", text: $customSubject)
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Name").font(.subheadline.weight(.semibold))
                    TextField("Your name", text: $name)
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email").font(.subheadline.weight(.semibold))
                    TextField("yourname@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    if !email.isEmpty && !isEmailValid {
                        Text("Enter a valid email address")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Message").font(.subheadline.weight(.semibold))
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    Text("\(message.count) / 1000")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Button {
                    submit()
                } label: {
                    HStack {
                        if isSending { ProgressView().tint(.white) }
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.prOrange)
                .disabled(!canSubmit || isSending)

                Text("We only use your email to respond to this feedback.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let result = resultText {
                    Text(result)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSuccess ? .prHeatGreen : .prHeatRed)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(.prBase)
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tile(_ s: Subject) -> some View {
        Button {
            subject = s
        } label: {
            VStack(spacing: 6) {
                Image(systemName: s.icon)
                    .font(.title3)
                Text(s.rawValue)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 78)
            .background(subject == s ? Color.prOrange : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(subject == s ? .white : .primary)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(subject == s ? Color.prOrange : Color(.separator), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(s.rawValue)\(subject == s ? ", selected" : "")")
    }

    private func submit() {
        isSending = true
        resultText = nil
        let finalSubject = subject == .other ? customSubject : subject.rawValue
        let payload = FeedbackRequest(
            name: name,
            email: email,
            subject: finalSubject,
            message: message,
            app_name: "PRDay"
        )
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://msg.calcs.top/api/feedback")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(payload)
                request.timeoutInterval = 30
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                    isSuccess = true
                    resultText = "Thank you! Your feedback has been sent."
                    message = ""
                } else {
                    isSuccess = false
                    resultText = String(data: data, encoding: .utf8) ?? "Something went wrong. Please try again."
                }
            } catch {
                isSuccess = false
                resultText = "Something went wrong. Please try again."
            }
            isSending = false
        }
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}
