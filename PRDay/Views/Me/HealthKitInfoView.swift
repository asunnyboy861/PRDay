import SwiftUI

struct HealthKitInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                    Text("HealthKit Integration")
                        .font(.title.bold())
                    Text("PRDay integrates with Apple Health through the HealthKit framework to read your resting heart rate, adding recovery context to your training dashboard.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Read-only: resting heart rate", systemImage: "checkmark.circle")
                        Label("Nothing is ever written to Apple Health", systemImage: "checkmark.circle")
                        Label("Health data stays on your device and in your private iCloud", systemImage: "checkmark.circle")
                        Label("Never shared with parents via family reports", systemImage: "checkmark.circle")
                    }
                    .font(.callout)
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 32)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
