import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = PlanViewModel()
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    phaseHeader
                    ForEach(viewModel.weeks) { week in
                        weekCard(week)
                    }
                    DisclaimerFooter()
                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(.prBase)
            .navigationTitle("Plan")
            .task { viewModel.load(context: context) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var phaseHeader: some View {
        HStack {
            Text("12-Week Plan")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
            Spacer()
            if let phase = viewModel.currentPhase {
                Text(phase.rawValue)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.prOrange.opacity(0.16), in: Capsule())
            }
        }
    }

    private func weekCard(_ week: PlanWeek) -> some View {
        let locked = viewModel.isLocked(week: week.week)
        return Group {
            if locked {
                lockedWeekCard(week)
            } else {
                NavigationLink {
                    WeekDetailView(week: week)
                } label: {
                    openWeekContent(week)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func openWeekContent(_ week: PlanWeek) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Week \(week.week)")
                    .font(.headline)
                Spacer()
                Text(week.phase.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(week.days.first?.title ?? "")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if week.week == 12 {
                Text("Taper week — reduced volume before your race.")
                    .font(.caption2)
                    .foregroundStyle(.prOrange)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .trailing) {
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .padding(.trailing, 14)
        }
    }

    private func lockedWeekCard(_ week: PlanWeek) -> some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.prOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Week \(week.week)")
                        .font(.headline)
                    Text("Unlock the full plan library with Pro")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.prSurface.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct WeekDetailView: View {
    let week: PlanWeek
    @State private var showChecklist = false
    @StateObject private var purchase = PurchaseManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(week.days.enumerated()), id: \.offset) { index, day in
                    dayCard(day, label: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index])
                }
                if let raceDate = raceDate(), PlanEngine.daysToRace(raceDate).map({ $0 <= 7 && $0 >= 0 }) == true {
                    Button {
                        showChecklist = true
                    } label: {
                        HStack {
                            Image(systemName: "checklist")
                            Text("Meet-Day Checklist")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(.prOrange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                DisclaimerFooter()
            }
            .padding(16)
        }
        .background(.prBase)
        .navigationTitle("Week \(week.week)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChecklist) { MeetChecklistView() }
    }

    private func raceDate() -> Date? {
        AthleteProfileBox.load(context: modelContext)?.raceDate
    }

    @Environment(\.modelContext) private var modelContext

    private func dayCard(_ day: PlanDay, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.prOrange)
                Text(day.title)
                    .font(.subheadline.weight(.bold))
                Spacer()
                if day.intensity == .high {
                    Image(systemName: "bolt.fill").foregroundStyle(.prHeatYellow)
                }
            }
            ForEach(day.blocks) { block in
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Text(block.name).font(.caption.weight(.semibold))
                        if let pace = block.targetPace {
                            Text(pace).font(.caption2).monospacedDigit().foregroundStyle(.prOrange)
                        }
                    }
                    Text(block.detail).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.prSurface, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct MeetChecklistView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("checklist.checked") private var checkedRaw = ""

    private let sections: [(String, [(String, String)])] = [
        ("Nutrition", [
            ("eat2h", "Eat a carb-focused meal 2-3 hours before"),
            ("hydrate", "Hydrate through the morning — stop large drinks 45 min out"),
            ("snacks", "Pack familiar snacks (no new foods on meet day)")
        ]),
        ("Sleep", [
            ("sleep8", "8+ hours — set a hard lights-out time"),
            ("wake", "Wake early enough for a full warm-up")
        ]),
        ("Equipment", [
            ("spikes", "Spikes + racing flats, both in the bag"),
            ("uniform", "Uniform + backup pin system"),
            ("sunscreen", "Sunscreen + hat for long meets")
        ]),
        ("Warm-up", [
            ("jog", "10-12 min easy jog"),
            ("drills", "Dynamic drills + 4 progressive strides"),
            ("mental", "Visualize your race plan once, calmly")
        ])
    ]

    private var checked: Set<String> {
        Set(checkedRaw.split(separator: ",").map(String.init))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(sections, id: \.0) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.0)
                                .font(.headline)
                            ForEach(section.1, id: \.0) { item in
                                Button {
                                    toggle(item.0)
                                } label: {
                                    HStack {
                                        Image(systemName: checked.contains(item.0) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(checked.contains(item.0) ? .prHeatGreen : .secondary)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(item.1).font(.subheadline)
                                        }
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(.prSurface, in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    DisclaimerFooter()
                }
                .padding()
            }
            .background(.prBase)
            .navigationTitle("Meet Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func toggle(_ id: String) {
        var set = checked
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        checkedRaw = set.joined(separator: ",")
    }
}
