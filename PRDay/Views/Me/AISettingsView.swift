import SwiftUI

struct AISettingsView: View {
    @StateObject private var manager = AIProfileManager.shared
    @State private var keyInput = ""
    @State private var testResult: String?
    @State private var isTesting = false
    @State private var showAppleInfo = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "apple.intelligence")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Intelligence (Built-in)").font(.headline)
                        Text(statusText).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if AppleIntelligenceGate.isAvailable {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
            } footer: {
                Text("Apple Intelligence runs on-device and is the default coach backend — no key needed. Requires a supported device with iOS 26+. Otherwise, add your own API key below for unlimited AI.")
            }

            Section {
                ForEach(AIProviderCatalog.all) { provider in
                    providerRow(provider)
                }
            } header: {
                Text("Bring Your Own AI Key")
            } footer: {
                Text("Keys are stored in your device Keychain only — never uploaded, never synced. Your own key unlocks unlimited AI form checks and coach answers.")
            }

            if manager.activeProviderID == "custom" {
                Section("Custom Provider") {
                    TextField("Endpoint (OpenAI-compatible base URL)", text: $manager.customEndpoint)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Model name", text: $manager.customModel)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Save Endpoint") {
                        manager.saveCustom(endpoint: manager.customEndpoint, model: manager.customModel)
                    }
                }
            }

            Section("Connection") {
                Button {
                    isTesting = true
                    testResult = nil
                    Task {
                        do {
                            _ = try await manager.testConnection()
                            testResult = "Connection OK"
                        } catch {
                            testResult = error.localizedDescription
                        }
                        isTesting = false
                    }
                } label: {
                    if isTesting {
                        ProgressView()
                    } else {
                        Text("Test Connection")
                    }
                }
                .disabled(manager.activeProviderID == nil || isTesting)
                if let result = testResult {
                    Text(result).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("AI Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { manager.activeProviderID = AIConfiguration.activeProviderID }
    }

    private var statusText: String {
        AppleIntelligenceGate.isAvailable ? "Available on this device" : "Not available — use your own key below"
    }

    private func providerRow(_ provider: AIProvider) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(provider.label).font(.headline)
                Spacer()
                if manager.activeProviderID == provider.id {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.prOrange)
                }
            }
            SecureField("API Key", text: $keyInput)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            HStack {
                Button("Save Key") {
                    manager.saveKey(keyInput, for: provider.id)
                    keyInput = ""
                    testResult = nil
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyInput.isEmpty)
                if !(AIConfiguration.apiKey(for: provider.id) ?? "").isEmpty {
                    Button("Remove", role: .destructive) {
                        manager.removeKey(for: provider.id)
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}
