import Foundation

enum StreakEngine {
    static func calendarDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func currentStreak(sessionDays: [Date], makeupDays: [Date], today: Date = Date.now) -> Int {
        let cal = Calendar.current
        let valid = Set((sessionDays + makeupDays).map(calendarDay))
        var cursor = cal.startOfDay(for: today)
        if !valid.contains(cursor) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            guard valid.contains(cursor) else { return 0 }
        }
        var streak = 0
        while valid.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    static func longestStreak(sessionDays: [Date], makeupDays: [Date]) -> Int {
        let sorted = Set((sessionDays + makeupDays).map(calendarDay)).sorted()
        guard !sorted.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for i in 1..<sorted.count {
            let gap = Calendar.current.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 99
            if gap == 1 {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    static func gapDaysSince(lastDay: Date?, today: Date = Date.now) -> Int? {
        guard let lastDay else { return nil }
        let cal = Calendar.current
        let gap = cal.dateComponents([.day], from: calendarDay(lastDay), to: calendarDay(today)).day
        return gap
    }

    static func makeupWindowDays(lastDay: Date?, today: Date = Date.now) -> Int? {
        guard let gap = gapDaysSince(lastDay: lastDay, today: today), gap > 1, gap <= 4 else { return nil }
        return gap - 1
    }
}
