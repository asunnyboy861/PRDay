import SwiftUI

struct CelebrationView: View {
    let record: PersonalRecord
    let deltaText: String?
    let watermark: Bool
    let onDismiss: () -> Void

    @State private var trigger = UUID()
    @State private var showShare = false
    @State private var shareImage: UIImage?

    var body: some View {
        ZStack {
            Color.prBase.opacity(0.97).ignoresSafeArea()
            ConfettiView(trigger: trigger)
            VStack(spacing: 18) {
                Spacer()
                Text("PR DAY!!!")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.prOrange)
                Text(record.event)
                    .font(.title2.weight(.bold))
                ScoreboardText(value: record.displayMark, size: 84)
                if let delta = deltaText {
                    Text("-\(delta) — new personal best")
                        .font(.headline)
                        .foregroundStyle(.prHeatGreen)
                }
                Spacer()
                PrimaryButton(title: "Share to Instagram", systemImage: "square.and.arrow.up") {
                    shareImage = makeCard()
                    showShare = shareImage != nil
                    if !showShare { onDismiss() }
                }
                .padding(.horizontal, 24)
                Button("Done") { onDismiss() }
                    .font(.headline)
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            trigger = UUID()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        .sheet(isPresented: $showShare, onDismiss: onDismiss) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private func makeCard() -> UIImage? {
        let payload = ReportPayload(
            recordID: nil,
            athleteName: "New PR",
            weekStart: record.achievedAt,
            completedCount: 0,
            plannedCount: 0,
            newPRCount: 1,
            streak: 0,
            focusText: "\(record.event) — \(record.displayMark)\(deltaText.map { " (-\($0))" } ?? "")"
        )
        let renderer = ImageRenderer(content: PRShareCardView(event: record.event, mark: record.displayMark, delta: deltaText, watermark: watermark))
        renderer.scale = 2
        return renderer.uiImage
    }
}

struct PRShareCardView: View {
    let event: String
    let mark: String
    let delta: String?
    let watermark: Bool

    var body: some View {
        ZStack {
            Color(red: 0.043, green: 0.059, blue: 0.078)
            VStack(spacing: 14) {
                Spacer()
                Text("PR DAY!!!")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.173))
                Text(event)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text(mark)
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                if let delta {
                    Text("-\(delta)")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.2, green: 0.78, blue: 0.35))
                }
                Spacer()
                HStack {
                    if watermark {
                        Text("Made with PRDay")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "apple.logo")
                        Text("Weather")
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 360, height: 640)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
