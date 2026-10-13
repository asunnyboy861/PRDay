import Foundation

struct PlanWeek: Identifiable, Equatable {
    var id: Int { week }
    let week: Int
    let phase: PlanPhase
    let days: [PlanDay]
}

enum PlanEngine {
    static let totalWeeks = 12

    static func generate(profile: AthleteProfile, bestRuns: [String: Double], anchorDate: Date = Date.now) -> [PlanWeek] {
        let group = profile.eventGroup
        let scale = profile.level.volumeScale
        let start = Calendar.current.startOfDay(for: anchorDate)
        return (1...totalWeeks).map { week in
            let phase = PlanPhase.phase(forWeek: week)
            let days = (1...7).map { dow -> PlanDay in
                let template = PlanLibrary.dayTemplate(group: group, phase: phase, dayOfWeek: dow)
                let id = "w\(week)d\(dow)"
                let date = Calendar.current.date(byAdding: .day, value: (week - 1) * 7 + (dow - 1), to: start) ?? start
                var blocks = template.blocks
                if week == totalWeeks {
                    blocks = taper(blocks: blocks)
                }
                return PlanDay(
                    id: id,
                    week: week,
                    dayOfWeek: dow,
                    date: date,
                    title: template.title,
                    focus: template.focus,
                    intensity: template.intensity,
                    blocks: resolvePaces(blocks: blocks, group: group, bestRuns: bestRuns),
                    workRestRatio: nil,
                    extraBreaksPerHour: nil,
                    indoorOnly: false,
                    volumeScale: scale,
                    note: nil
                )
            }
            return PlanWeek(week: week, phase: phase, days: days)
        }
    }

    static func todayPlanDay(weeks: [PlanWeek], date: Date = Date.now) -> PlanDay? {
        let cal = Calendar.current
        let target = cal.startOfDay(for: date)
        return weeks.flatMap { $0.days }.first { cal.startOfDay(for: $0.date) == target }
    }

    static func daysToRace(_ raceDate: Date?, from date: Date = Date.now) -> Int? {
        guard let raceDate else { return nil }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: raceDate)).day
    }

    private static func taper(blocks: [WorkoutBlock]) -> [WorkoutBlock] {
        blocks.map { b in
            var b = b
            if b.detail.contains(" x ") {
                b.detail = b.detail.replacingOccurrences(of: " x ", with: " (reduced) x ")
            }
            return b
        }
    }

    private static func resolvePaces(blocks: [WorkoutBlock], group: EventGroup, bestRuns: [String: Double]) -> [WorkoutBlock] {
        guard group == .sprints || group == .midDistance else { return blocks }
        guard let anchor = bestRuns["1600m"] ?? bestRuns["800m"].map({ PaceEngine.riegel(t1Sec: $0, d1Meters: 800, d2Meters: 1600) }) else {
            return blocks
        }
        let anchorMeters: Double = bestRuns["1600m"] != nil ? 1600 : 800
        let paces = PaceEngine.trainingPaces(prSec: anchor, prMeters: anchorMeters)
        return blocks.map { block in
            var b = block
            switch b.targetPace {
            case "easy": b.targetPace = PaceEngine.formatPace(paces.easyPaceSecPerMile)
            case "threshold": b.targetPace = PaceEngine.formatPace(paces.thresholdPaceSecPerMile)
            case "interval": b.targetPace = PaceEngine.formatPace(paces.intervalPaceSecPerMile)
            case "rep": b.targetPace = PaceEngine.formatPace(paces.repPaceSecPerMile)
            default: break
            }
            return b
        }
    }
}
