import SwiftUI

struct WorkoutPlayerView: View {
    let day: PlanDay
    let onFinish: (Int, Double?, String?) -> Void

    @State private var blockIndex = 0
    @State private var secondsLeft = 0
    @State private var isResting = false
    @State private var timer: Timer?
    @State private var rpe = 5
    @Environment(\.dismiss) private var dismiss

    private var currentBlock: WorkoutBlock? {
        day.blocks.indices.contains(blockIndex) ? day.blocks[blockIndex] : nil
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("W\(day.week) · \(day.focus)")
                    .font(.headline)
                Spacer()
                Button("End") { dismiss() }
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            VStack(spacing: 8) {
                Text("Block \(blockIndex + 1) of \(day.blocks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(currentBlock?.name ?? "Complete")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                if let pace = currentBlock?.targetPace {
                    Text(pace)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.prOrange)
                }
                Text(currentBlock?.detail ?? "")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            if secondsLeft > 0 {
                VStack(spacing: 4) {
                    ScoreboardText(value: PaceEngine.formatCountdown(secondsLeft), size: 84)
                    Text(isResting ? "REST" : "WORK")
                        .font(.headline)
                        .foregroundStyle(isResting ? .prHeatYellow : .prHeatGreen)
                }
            } else {
                ScoreboardText(value: "--:--", size: 84)
                    .opacity(0.25)
            }

            HStack(spacing: 12) {
                if secondsLeft == 0 {
                    Button {
                        startWork(minuteCount: 3)
                    } label: {
                        Label("Work 3:00", systemImage: "figure.run")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.prHeatGreen)
                    Button {
                        startRest(minutes: 2)
                    } label: {
                        Label("Rest 2:00", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(.prHeatYellow)
                } else {
                    Button {
                        stopTimer()
                    } label: {
                        Label("Stop Timer", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                }
                Button {
                    nextBlock()
                } label: {
                    Label(blockIndex + 1 < day.blocks.count ? "Next Block" : "Finish", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.prOrange)
            }
            .padding(.horizontal, 20)

            if blockIndex + 1 >= day.blocks.count {
                VStack(spacing: 10) {
                    Text("How hard was it? RPE \(rpe)")
                        .font(.headline)
                    Slider(value: Binding(get: { Double(rpe) }, set: { rpe = Int($0) }), in: 1...10, step: 1)
                        .padding(.horizontal, 20)
                    PrimaryButton(title: "Log & Finish") {
                        finishAndLog()
                    }
                    .padding(.horizontal, 20)
                }
            }
            DisclaimerFooter().padding(.bottom, 16)
        }
        .background(.prBase)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            stopTimer()
        }
        .interactiveDismissDisabled(secondsLeft > 0)
    }

    private func startRest(minutes: Int) {
        isResting = true
        secondsLeft = minutes * 60
        runTimer()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    private func startWork(minuteCount: Int) {
        isResting = false
        secondsLeft = minuteCount * 60
        runTimer()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func nextBlock() {
        stopTimer()
        if blockIndex + 1 < day.blocks.count {
            blockIndex += 1
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            finishAndLog()
        }
    }

    private func finishAndLog() {
        stopTimer()
        UIApplication.shared.isIdleTimerDisabled = false
        onFinish(rpe, nil, nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private func runTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            secondsLeft -= 1
            if secondsLeft <= 0 {
                stopTimer()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
