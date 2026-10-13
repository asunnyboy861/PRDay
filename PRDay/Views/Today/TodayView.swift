import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = TodayViewModel()
    @StateObject private var purchase = PurchaseManager.shared
    @StateObject private var weather = WeatherProvider.shared
    @State private var showPlayer = false
    @State private var showAskCoach = false
    @State private var showLog = false
    @State private var showMakeup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if let day = viewModel.today {
                        workoutCard(day)
                    } else {
                        emptyCard
                    }
                    heatCard
                    if viewModel.makeupWindow != nil && !viewModel.completedToday {
                        makeupCard
                    }
                    askCoachButton
                    DisclaimerFooter()
                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(.prBase)
            .task {
                await viewModel.load(context: context, purchase: purchase, weather: weather)
            }
            .refreshable {
                await weather.refresh()
                await viewModel.load(context: context, purchase: purchase, weather: weather)
            }
            .navigationDestination(isPresented: $showPlayer) {
                if let day = viewModel.today {
                    WorkoutPlayerView(day: day) { rpe, mark, markEvent in
                        Task {
                            await viewModel.logWorkout(context: context, day: day, rpe: rpe, mark: mark, markEvent: markEvent, weather: weather)
                            showLog = viewModel.prCelebration == nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showAskCoach) { AskCoachView() }
            .sheet(isPresented: $showLog) { LogSheet(viewModel: viewModel) }
            .overlay {
                if let record = viewModel.prCelebration {
                    CelebrationView(record: record, deltaText: viewModel.prDeltaText, watermark: !purchase.isPro) {
                        viewModel.prCelebration = nil
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Today")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.prOrange)
                Text("\(viewModel.streak)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
            }
            .accessibilityLabel("Streak \(viewModel.streak) days")
        }
    }

    private var heatCard: some View {
        Group {
            if let flag = weather.flag {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        FlagChip(flag: flag)
                        Spacer()
                        if let snap = weather.snapshot {
                            Text("\(Int(snap.tempF))°F · \(Int(snap.humidity))% humidity")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(flag.activityRule)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weather unavailable")
                        .font(.subheadline.weight(.semibold))
                    Text("Follow your coach's call for today.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            WeatherAttribution(compact: true)
                .padding(6)
        }
    }

    private func workoutCard(_ day: PlanDay) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(day.title.uppercased())
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .lineLimit(2)
                Spacer()
                Text("W\(day.week)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            if let note = day.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.prHeatOrange)
            }
            ForEach(day.blocks) { block in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(block.name).font(.subheadline.weight(.bold))
                        if let pace = block.targetPace {
                            Text(pace)
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.prOrange)
                        }
                    }
                    Text(block.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            PrimaryButton(title: viewModel.completedToday ? "Logged ✓ — View Session" : "Start", systemImage: "play.fill") {
                showPlayer = true
            }
        }
        .padding(18)
        .background(.prSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var emptyCard: some View {
        VStack(spacing: 10) {
            Text("No plan yet")
                .font(.headline)
            Text("Open the Me tab and set your goal race to generate your plan.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.prSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var makeupCard: some View {
        Button {
            showMakeup = true
        } label: {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Missed a day?")
                        .font(.subheadline.weight(.semibold))
                    Text("You can log a makeup within \(viewModel.makeupWindow ?? 0) day\(viewModel.makeupWindow == 1 ? "" : "s") to keep your streak.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showMakeup) {
            MakeupSheet(viewModel: viewModel)
        }
    }

    private var askCoachButton: some View {
        Button {
            showAskCoach = true
        } label: {
            HStack {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                Text("Ask Coach")
                    .font(.headline)
                Spacer()
                Text("AI").font(.caption.weight(.bold)).foregroundStyle(.prOrange)
            }
            .padding(16)
            .background(.prSurfaceAlt, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct MakeupSheet: View {
    @ObservedObject var viewModel: TodayViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Which day are you making up?")
                    .font(.headline)
                ForEach(1...(viewModel.makeupWindow ?? 1), id: \.self) { back in
                    if let day = Calendar.current.date(byAdding: .day, value: -back, to: Date.now) {
                        Button {
                            viewModel.logMakeup(context: modelContext, day: day)
                            dismiss()
                        } label: {
                            Text(DateFormatter.localizedString(from: day, dateStyle: .medium, timeStyle: .none))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.prSurface, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Makeup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }

    @Environment(\.modelContext) private var modelContext
}

struct LogSheet: View {
    @ObservedObject var viewModel: TodayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var rpe = 5
    @State private var markText = ""
    @State private var event = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("How hard was it? (RPE 1-10)") {
                    Slider(value: Binding(get: { Double(rpe) }, set: { rpe = Int($0) }), in: 1...10, step: 1)
                    Text("RPE \(rpe)")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }
                Section("Optional: log a mark") {
                    Picker("Event", selection: $event) {
                        Text("None").tag("")
                        ForEach(EventGroup.allCases.flatMap { $0.events }, id: \.self) { e in
                            Text(e).tag(e)
                        }
                    }
                    if !event.isEmpty {
                        TextField(event.contains("Jump") || event.contains("Throw") ? "Mark in meters (e.g. 6.12)" : "Time in seconds (e.g. 11.45)", text: $markText)
                            .keyboardType(.decimalPad)
                    }
                }
                Section {
                    Button("Save Log") {
                        let mark = Double(markText)
                        Task {
                            await viewModel.logWorkout(
                                context: modelContext,
                                day: viewModel.today ?? PlanDay(id: "manual", week: 1, dayOfWeek: 1, date: Date.now, title: "Manual Log", focus: "Free", intensity: .moderate, blocks: [], workRestRatio: nil, extraBreaksPerHour: nil, indoorOnly: false, volumeScale: 1, note: nil),
                                rpe: rpe,
                                mark: mark,
                                markEvent: mark != nil && !event.isEmpty ? event : nil,
                                weather: WeatherProvider.shared
                            )
                        }
                        dismiss()
                    }
                    .disabled(!markText.isEmpty && event.isEmpty)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
}
