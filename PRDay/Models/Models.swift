import Foundation
import SwiftData

enum EventGroup: String, Codable, CaseIterable, Identifiable {
    case sprints = "Sprints"
    case midDistance = "Mid-Distance"
    case jumps = "Jumps"
    case throwsEvent = "Throws"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sprints: return "figure.run"
        case .midDistance: return "figure.track.and.field"
        case .jumps: return "figure.gymnastics"
        case .throwsEvent: return "figure.strengthtraining.traditional"
        }
    }

    var events: [String] {
        switch self {
        case .sprints: return ["100m", "200m", "400m", "110mH", "300mH"]
        case .midDistance: return ["800m", "1600m", "3200m"]
        case .jumps: return ["LongJump", "HighJump", "TripleJump", "PoleVault"]
        case .throwsEvent: return ["ShotPut", "Discus"]
        }
    }

    var displayName: String {
        switch self {
        case .sprints: return "Sprints & Hurdles"
        case .midDistance: return "Mid-Distance"
        case .jumps: return "Jumps"
        case .throwsEvent: return "Throws"
        }
    }
}

enum AthleteLevel: String, Codable, CaseIterable, Identifiable {
    case firstSeason = "First Season"
    case varsity = "Varsity"
    case elite = "Elite"

    var id: String { rawValue }
    var volumeScale: Double {
        switch self {
        case .firstSeason: return 0.8
        case .varsity: return 1.0
        case .elite: return 1.2
        }
    }
}

enum HeatFlag: String, Codable, CaseIterable {
    case green, yellow, orange, red, black

    var activityRule: String {
        switch self {
        case .green: return "Normal activities"
        case .yellow: return "Work:rest 2:1, +3 rest breaks/hour"
        case .orange: return "Work:rest 1:1, move speed work to early AM"
        case .red: return "Indoor only, minimal outdoor"
        case .black: return "Suspend outdoor practice"
        }
    }
}

enum PlanPhase: String, CaseIterable {
    case base = "Base"
    case build = "Build"
    case peak = "Peak"
    case taper = "Taper"

    static func phase(forWeek week: Int, totalWeeks: Int = 12) -> PlanPhase {
        switch week {
        case ..<4: return .base
        case 4...8: return .build
        case 9...11: return .peak
        default: return .taper
        }
    }
}

struct WorkoutBlock: Equatable, Codable, Identifiable {
    var id: String { name }
    var name: String
    var detail: String
    var targetPace: String?
}

struct PlanDay: Equatable, Identifiable {
    enum Intensity: String, Codable { case low, moderate, high }

    var id: String
    var week: Int
    var dayOfWeek: Int
    var date: Date
    var title: String
    var focus: String
    var intensity: Intensity
    var blocks: [WorkoutBlock]
    var workRestRatio: String?
    var extraBreaksPerHour: Int?
    var indoorOnly: Bool
    var volumeScale: Double
    var note: String?

    static func == (lhs: PlanDay, rhs: PlanDay) -> Bool { lhs.id == rhs.id }
}

@Model
final class AthleteProfile {
    var eventGroupRaw: String = EventGroup.sprints.rawValue
    var levelRaw: String = AthleteLevel.firstSeason.rawValue
    var goalRace: String = ""
    var raceDate: Date?
    var onboardingCompleted: Bool = false
    var isParentMode: Bool = false
    var createdAt: Date = Date.now

    init() {}

    var eventGroup: EventGroup {
        get { EventGroup(rawValue: eventGroupRaw) ?? .sprints }
        set { eventGroupRaw = newValue.rawValue }
    }

    var level: AthleteLevel {
        get { AthleteLevel(rawValue: levelRaw) ?? .firstSeason }
        set { levelRaw = newValue.rawValue }
    }
}

@Model
final class WorkoutSession {
    var clientUUID: UUID = UUID()
    var date: Date = Date.now
    var planDayID: String = ""
    var title: String = ""
    var completed: Bool = true
    var rpe: Int = 5
    var actualMark: Double?
    var markEvent: String?
    var wbgtAtWorkout: Double?
    var weatherSummary: String?
    var notes: String?

    init() {}
}

@Model
final class PersonalRecord {
    var event: String = ""
    var mark: Double = 0
    var achievedAt: Date = Date.now
    var windAssisted: Bool = false
    var isTime: Bool = true

    init() {}

    var displayMark: String {
        if isTime {
            return PaceEngine.formatSeconds(mark)
        }
        return String(format: "%.2f m", mark)
    }
}

@Model
final class StreakState {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var version: Int = 0

    init() {}
}

@Model
final class StreakEvent {
    enum Kind: String, Codable { case completed, makeup, resumed }

    var kindRaw: String = Kind.completed.rawValue
    var day: Date = Date.now
    var createdAt: Date = Date.now

    init() {}

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .completed }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class WeeklyReport {
    var weekStart: Date = Date.now
    var completedCount: Int = 0
    var plannedCount: Int = 0
    var newPRCount: Int = 0
    var streak: Int = 0
    var focusText: String = ""
    var createdAt: Date = Date.now

    init() {}
}

@Model
final class MeetChecklistState {
    var checkedIDs: [String] = []
    var raceDate: Date?

    init() {}
}
