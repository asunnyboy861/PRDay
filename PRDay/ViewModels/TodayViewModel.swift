import Foundation
import SwiftData
import Observation

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var today: PlanDay?
    @Published var streak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var makeupWindow: Int?
    @Published var completedToday = false
    @Published var lastLogRPE = 5
    @Published var prCelebration: PersonalRecord?
    @Published var prDeltaText: String?

    private var weeks: [PlanWeek] = []

    func load(context: ModelContext, purchase: PurchaseManager, weather: WeatherProvider) async {
        guard let profile = AthleteProfileBox.load(context: context) else { return }
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let records = (try? context.fetch(FetchDescriptor<PersonalRecord>())) ?? []
        let bestRuns = bestRunMarks(records: records)
        weeks = PlanEngine.generate(profile: profile, bestRuns: bestRuns)
        today = PlanEngine.todayPlanDay(weeks: weeks)

        if weather.flag == nil {
            await weather.refresh()
        }
        if let flag = weather.flag, let day = today, purchase.isPro {
            today = PlanAdjustmentEngine.adjust(day: day, flag: flag, daysToRace: PlanEngine.daysToRace(profile.raceDate))
            if flag == .red || flag == .black {
                NotificationService.sendRedFlagAlert(flag: flag)
            }
        }

        let todayStart = Calendar.current.startOfDay(for: Date.now)
        completedToday = sessions.contains { $0.completed && Calendar.current.startOfDay(for: $0.date) == todayStart }

        let sessionDays = sessions.filter { $0.completed }.map { $0.date }
        let makeups = (try? context.fetch(FetchDescriptor<StreakEvent>()))?.filter { $0.kind == .makeup }.map { $0.day } ?? []
        streak = StreakEngine.currentStreak(sessionDays: sessionDays, makeupDays: makeups)
        longestStreak = max(StreakEngine.longestStreak(sessionDays: sessionDays, makeupDays: makeups), loadLongest())
        makeupWindow = StreakEngine.makeupWindowDays(lastDay: sessionDays.max())
    }

    func logWorkout(context: ModelContext, day: PlanDay, rpe: Int, mark: Double?, markEvent: String?, weather: WeatherProvider) async {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date.now)
        let existing = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        if let already = existing.first(where: { $0.completed && cal.startOfDay(for: $0.date) == todayStart && $0.planDayID == day.id }) {
            _ = already
            return
        }
        let session = WorkoutSession()
        session.clientUUID = UUID()
        session.date = Date.now
        session.planDayID = day.id
        session.title = day.title
        session.completed = true
        session.rpe = rpe
        session.actualMark = mark
        session.markEvent = markEvent
        session.wbgtAtWorkout = weather.snapshot.map { WBGTEngine.compute(tempF: $0.tempF, humidity: $0.humidity).wbgtF }
        session.weatherSummary = weather.snapshot.map { "\(Int($0.tempF))°F \($0.condition)" }
        context.insert(session)

        if let event = markEvent, let mark {
            await detectPR(context: context, event: event, mark: mark)
        }

        let event = StreakEvent()
        event.kind = .completed
        event.day = Date.now
        context.insert(event)

        try? context.save()
        completedToday = true
        let sessionDays = existing.filter { $0.completed }.map { $0.date } + [Date.now]
        let makeups = (try? context.fetch(FetchDescriptor<StreakEvent>()))?.filter { $0.kind == .makeup }.map { $0.day } ?? []
        streak = StreakEngine.currentStreak(sessionDays: sessionDays, makeupDays: makeups)
        if streak > loadLongest() {
            saveLongest(streak)
            longestStreak = streak
        }
    }

    func logMakeup(context: ModelContext, day: Date) {
        let event = StreakEvent()
        event.kind = .makeup
        event.day = day
        context.insert(event)
        try? context.save()
    }

    func prGapText(records: [PersonalRecord], event: String, mark: Double) -> String? {
        guard let best = records.filter({ $0.event == event && !$0.windAssisted }).map({ $0.mark }).min(),
              mark > best else { return nil }
        return PaceEngine.formatSeconds(mark - best)
    }

    private func detectPR(context: ModelContext, event: String, mark: Double) async {
        let records = (try? context.fetch(FetchDescriptor<PersonalRecord>())) ?? []
        let isTime = event.contains("m")
        if let best = records.filter({ $0.event == event && !$0.windAssisted }).map({ $0.mark }).min() {
            let better = isTime ? mark < best : mark > best
            guard better else { return }
            prDeltaText = isTime ? PaceEngine.formatSeconds(abs(best - mark)) : String(format: "%.2f m", abs(mark - best))
        } else {
            prDeltaText = nil
        }
        let record = PersonalRecord()
        record.event = event
        record.mark = mark
        record.achievedAt = Date.now
        record.isTime = isTime
        context.insert(record)
        prCelebration = record
    }

    private func bestRunMarks(records: [PersonalRecord]) -> [String: Double] {
        var best: [String: Double] = [:]
        for r in records where r.isTime && !r.windAssisted {
            let current = best[r.event]
            if current == nil || r.mark < current! {
                best[r.event] = r.mark
            }
        }
        return best
    }

    private func loadLongest() -> Int {
        UserDefaults.standard.integer(forKey: "streak.longest")
    }

    private func saveLongest(_ value: Int) {
        UserDefaults.standard.set(value, forKey: "streak.longest")
    }
}
