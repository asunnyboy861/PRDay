import SwiftUI
import SwiftData
import Charts

struct PRsView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = PRsViewModel()
    @State private var showAdd = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    eventPicker
                    if let best = viewModel.bestRecord {
                        bestCard(best)
                        chartCard
                    }
                    timelineCard
                    if viewModel.freeEventLimitReached {
                        lockCard
                    }
                    DisclaimerFooter()
                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(.prBase)
            .navigationTitle("PRs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if viewModel.canAdd(event: viewModel.selectedEvent ?? "") {
                            showAdd = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add personal record")
                }
            }
            .sheet(isPresented: $showAdd) { AddPRSheet(viewModel: viewModel) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .task {
                let group = AthleteProfileBox.load(context: context)?.eventGroup ?? .sprints
                viewModel.load(context: context, group: group)
            }
        }
    }

    private var eventPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(currentGroup.events, id: \.self) { event in
                    Button {
                        viewModel.selectedEvent = event
                    } label: {
                        Text(event)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedEvent == event ? .prOrange : .prSurface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var currentGroup: EventGroup {
        guard let event = viewModel.selectedEvent else { return .sprints }
        return EventGroup.allCases.first { $0.events.contains(event) } ?? .sprints
    }

    private func bestCard(_ best: PersonalRecord) -> some View {
        VStack(spacing: 4) {
            Text("PERSONAL BEST")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            ScoreboardText(value: best.displayMark, size: 72)
            if best.windAssisted {
                Text("Wind-assisted — not an official PR")
                    .font(.caption2)
                    .foregroundStyle(.prHeatYellow)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.prSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.headline)
            let isTime = viewModel.selectedEvent?.contains("m") ?? true
            Chart(viewModel.selectedRecords) { record in
                LineMark(x: .value("Date", record.achievedAt), y: .value(isTime ? "Seconds" : "Meters", isTime ? record.mark : -record.mark))
                    .foregroundStyle(.prOrange)
                    .symbol(Circle())
                RuleMark(y: .value("Best", isTime ? bestValue : -bestValue))
                    .foregroundStyle(.prHeatGreen)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(isTime ? PaceEngine.formatSeconds(v) : String(format: "%.2f", -v))
                                .font(.caption2)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var bestValue: Double {
        viewModel.bestRecord?.mark ?? 0
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timeline")
                .font(.headline)
            if viewModel.selectedRecords.isEmpty {
                Text("No marks yet for \(viewModel.selectedEvent ?? ""). Tap + to add your first.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(viewModel.selectedRecords) { record in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.displayMark)
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                        Text(DateFormatter.localizedString(from: record.achievedAt, dateStyle: .medium, timeStyle: .none))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if record.windAssisted {
                        Text("Wind")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.prHeatYellow)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var lockCard: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "lock.fill").foregroundStyle(.prOrange)
                Text("Free tracks your first 3 events — Pro tracks all events")
                    .font(.footnote)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct AddPRSheet: View {
    @ObservedObject var viewModel: PRsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var markText = ""
    @State private var windAssisted = false
    @State private var event = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    Picker("Event", selection: $event) {
                        ForEach(EventGroup.allCases.flatMap { $0.events }, id: \.self) { e in
                            Text(e).tag(e)
                        }
                    }
                }
                Section {
                    TextField(event.contains("Jump") || event.contains("Throw") ? "Mark in meters (e.g. 6.12)" : "Time in seconds (e.g. 11.45)", text: $markText)
                        .keyboardType(.decimalPad)
                    Toggle("Wind-assisted (+2.0 m/s or more)", isOn: $windAssisted)
                } footer: {
                    Text("Wind-assisted marks are saved but not counted as official PRs.")
                }
                Section {
                    Button("Save Record") {
                        guard let mark = Double(markText), !event.isEmpty else { return }
                        viewModel.addRecord(context: modelContext, event: event, mark: mark, windAssisted: windAssisted)
                        dismiss()
                    }
                    .disabled(Double(markText) == nil || event.isEmpty)
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear { event = viewModel.selectedEvent ?? "" }
        }
    }

    @Environment(\.modelContext) private var modelContext
}
