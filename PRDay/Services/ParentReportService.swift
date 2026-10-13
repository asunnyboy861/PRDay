import Foundation
import SwiftUI

final class ParentReportService: ObservableObject {
    static let shared = ParentReportService()

    struct WeekSummary {
        let completedCount: Int
        let plannedCount: Int
        let newPRCount: Int
        let streak: Int
        let focusText: String
    }

    func buildSummary(sessions: [WorkoutSession], records: [PersonalRecord], streak: Int, planDays: [PlanDay]) -> WeekSummary {
        let cal = Calendar.current
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date.now)) ?? Date.now
        let weekSessions = sessions.filter { $0.date >= weekStart && $0.completed }
        let planned = planDays.filter { $0.date >= weekStart && $0.date <= Date.now && $0.intensity != .low || $0.date >= weekStart && $0.date <= Date.now }.count
        let newPRs = records.filter { $0.achievedAt >= weekStart && !$0.windAssisted }.count
        let focus: String
        if newPRs > 0 {
            focus = "\(newPRs) new PR\(newPRs == 1 ? "" : "s") this week — keep the momentum."
        } else if weekSessions.count >= 5 {
            focus = "Consistent training week. Recovery matters next week."
        } else {
            focus = "Focus on completing the plan next week."
        }
        return WeekSummary(
            completedCount: weekSessions.count,
            plannedCount: max(planned, weekSessions.count),
            newPRCount: newPRs,
            streak: streak,
            focusText: focus
        )
    }

    @MainActor
    func renderCard(payload: ReportPayload, watermark: Bool) -> UIImage? {
        let renderer = ImageRenderer(content: ReportCardView(payload: payload, watermark: watermark))
        renderer.scale = 2
        return renderer.uiImage
    }
}

struct ReportCardView: View {
    let payload: ReportPayload
    let watermark: Bool

    var body: some View {
        ZStack {
            Color.white
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PRDay Weekly")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.173))
                    Text("\(payload.athleteName) — week of \(Self.dateString(payload.weekStart))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 16) {
                    stat(value: "\(payload.completedCount)/\(max(payload.plannedCount, 1))", label: "Workouts")
                    stat(value: "\(payload.newPRCount)", label: "New PRs")
                    stat(value: "\(payload.streak)", label: "Streak")
                }
                Text(payload.focusText)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .padding(.top, 4)
                Spacer(minLength: 0)
                if watermark {
                    Text("Made with PRDay")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 360, height: 640)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
    }

    static func dateString(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }
}
