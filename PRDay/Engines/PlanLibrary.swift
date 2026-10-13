import Foundation

struct DayTemplate {
    let focus: String
    let intensity: PlanDay.Intensity
    let title: String
    let blocks: [WorkoutBlock]
}

enum PlanLibrary {
    static func dayTemplate(group: EventGroup, phase: PlanPhase, dayOfWeek: Int) -> DayTemplate {
        switch group {
        case .sprints:
            return sprints(phase: phase, day: dayOfWeek)
        case .midDistance:
            return midDistance(phase: phase, day: dayOfWeek)
        case .jumps:
            return jumps(phase: phase, day: dayOfWeek)
        case .throwsEvent:
            return throwsGroup(phase: phase, day: dayOfWeek)
        }
    }

    private static func sprints(phase: PlanPhase, day: Int) -> DayTemplate {
        switch day {
        case 1:
            return DayTemplate(focus: "Acceleration", intensity: .high, title: "Acceleration & Blocks", blocks: [
                .init(name: "Warm-up", detail: "12 min jog + dynamic drills + 4 build-ups", targetPace: nil),
                .init(name: "Block starts", detail: "\(repCount(phase, base: 6)) x 20m from blocks, full recovery", targetPace: nil),
                .init(name: "Accel runs", detail: "\(repCount(phase, base: 4)) x 30m push-run, walk-back recovery", targetPace: nil),
                .init(name: "Cooldown", detail: "8 min easy jog + mobility", targetPace: nil)
            ])
        case 2:
            return DayTemplate(focus: "Tempo", intensity: .moderate, title: "Tempo Endurance", blocks: [
                .init(name: "Warm-up", detail: "10 min jog + drills", targetPace: nil),
                .init(name: "Tempo runs", detail: "\(repCount(phase, base: 8)) x 150m @ ~75% effort, 90s walk", targetPace: nil),
                .init(name: "Core", detail: "3 rounds: plank, side plank, dead bug", targetPace: nil),
                .init(name: "Cooldown", detail: "6 min easy jog", targetPace: nil)
            ])
        case 3:
            return DayTemplate(focus: "Technique", intensity: .low, title: "Technique & Mechanics", blocks: [
                .init(name: "Warm-up", detail: "10 min jog + hurdle mobility", targetPace: nil),
                .init(name: "Drills", detail: "A-skips, B-skips, high knees, wall drills — 3 x 20m each", targetPace: nil),
                .init(name: "Strides", detail: "6 x 60m relaxed, focus on posture", targetPace: nil),
                .init(name: "Cooldown", detail: "Stretch routine", targetPace: nil)
            ])
        case 4:
            return DayTemplate(focus: "Speed Endurance", intensity: .high, title: "Speed Endurance", blocks: [
                .init(name: "Warm-up", detail: "12 min jog + drills + 3 build-ups", targetPace: nil),
                .init(name: "Special endurance", detail: "\(repCount(phase, base: 3)) x 200m @ 95%, 6 min rest", targetPace: nil),
                .init(name: "Float runs", detail: "2 x 150m float-relax-float", targetPace: nil),
                .init(name: "Cooldown", detail: "8 min jog + legs up wall", targetPace: nil)
            ])
        case 5:
            return DayTemplate(focus: "Tempo", intensity: .moderate, title: "Extensive Tempo", blocks: [
                .init(name: "Warm-up", detail: "10 min jog + drills", targetPace: nil),
                .init(name: "Circuits", detail: "6 x 100m @ 70% + bodyweight strength station", targetPace: nil),
                .init(name: "Med ball", detail: "3 x 10 throws", targetPace: nil),
                .init(name: "Cooldown", detail: "6 min jog", targetPace: nil)
            ])
        case 6:
            return DayTemplate(focus: "Speed", intensity: .high, title: "Speed Day", blocks: [
                .init(name: "Warm-up", detail: "12 min jog + drills", targetPace: nil),
                .init(name: "Flying sprints", detail: "\(repCount(phase, base: 5)) x 20m fly, 4 min rest", targetPace: nil),
                .init(name: "Starts", detail: "4 x 10m push-up position starts", targetPace: nil),
                .init(name: "Cooldown", detail: "8 min jog", targetPace: nil)
            ])
        default:
            return DayTemplate(focus: "Recovery", intensity: .low, title: "Rest or Easy Recovery", blocks: [
                .init(name: "Optional", detail: "20 min easy walk/bike + full stretch", targetPace: nil)
            ])
        }
    }

    private static func midDistance(phase: PlanPhase, day: Int) -> DayTemplate {
        switch day {
        case 1:
            return DayTemplate(focus: "Intervals", intensity: .high, title: "VO2 Intervals", blocks: [
                .init(name: "Warm-up", detail: "12 min easy + drills + 4 strides", targetPace: nil),
                .init(name: "Intervals", detail: "\(repCount(phase, base: 5)) x 800m, 2:30 jog recovery", targetPace: "interval"),
                .init(name: "Cooldown", detail: "10 min easy", targetPace: "easy")
            ])
        case 2:
            return DayTemplate(focus: "Easy", intensity: .low, title: "Easy Distance", blocks: [
                .init(name: "Easy run", detail: "30-40 min conversational", targetPace: "easy"),
                .init(name: "Strides", detail: "4 x 80m relaxed", targetPace: nil)
            ])
        case 3:
            return DayTemplate(focus: "Hills", intensity: .moderate, title: "Hill Strength", blocks: [
                .init(name: "Warm-up", detail: "12 min easy + drills", targetPace: nil),
                .init(name: "Hill repeats", detail: "\(repCount(phase, base: 8)) x 12s hill sprint, walk down", targetPace: nil),
                .init(name: "Cooldown", detail: "8 min easy", targetPace: "easy")
            ])
        case 4:
            return DayTemplate(focus: "Tempo", intensity: .moderate, title: "Threshold Tempo", blocks: [
                .init(name: "Warm-up", detail: "10 min easy + drills", targetPace: nil),
                .init(name: "Tempo", detail: "20-24 min steady @ threshold", targetPace: "threshold"),
                .init(name: "Cooldown", detail: "8 min easy", targetPace: "easy")
            ])
        case 5:
            return DayTemplate(focus: "Easy", intensity: .low, title: "Recovery Run", blocks: [
                .init(name: "Easy run", detail: "25 min very easy + mobility", targetPace: "easy")
            ])
        case 6:
            return DayTemplate(focus: "Race Prep", intensity: .high, title: "Race / Time Trial", blocks: [
                .init(name: "Warm-up", detail: "15 min + drills + 4 strides", targetPace: nil),
                .init(name: "Race pace set", detail: "2 x 400m @ goal race pace, full recovery", targetPace: "rep"),
                .init(name: "Cooldown", detail: "10 min easy", targetPace: "easy")
            ])
        default:
            return DayTemplate(focus: "Long", intensity: .low, title: "Long Easy Run", blocks: [
                .init(name: "Long run", detail: "45-60 min easy", targetPace: "easy")
            ])
        }
    }

    private static func jumps(phase: PlanPhase, day: Int) -> DayTemplate {
        switch day {
        case 1:
            return DayTemplate(focus: "Approach", intensity: .moderate, title: "Approach Technique", blocks: [
                .init(name: "Warm-up", detail: "10 min jog + drills", targetPace: nil),
                .init(name: "Approach runs", detail: "\(repCount(phase, base: 10)) x full approach, no jump", targetPace: nil),
                .init(name: "Takeoff pops", detail: "6 short-approach takeoffs", targetPace: nil),
                .init(name: "Cooldown", detail: "Stretch", targetPace: nil)
            ])
        case 2:
            return DayTemplate(focus: "Plyo", intensity: .high, title: "Plyometrics", blocks: [
                .init(name: "Warm-up", detail: "10 min + leg swings + ankling", targetPace: nil),
                .init(name: "Bounds", detail: "4 x 30m alternate-leg bounds", targetPace: nil),
                .init(name: "Hops", detail: "3 x 10 single-leg hops each side", targetPace: nil),
                .init(name: "Cooldown", detail: "Foam roll", targetPace: nil)
            ])
        case 3:
            return DayTemplate(focus: "Full Session", intensity: .high, title: "Jump Session", blocks: [
                .init(name: "Warm-up", detail: "12 min + approach rehearsals", targetPace: nil),
                .init(name: "Jumps", detail: "\(repCount(phase, base: 8)) full jumps from full approach", targetPace: nil),
                .init(name: "Cooldown", detail: "Stretch + notes on runway marks", targetPace: nil)
            ])
        case 4:
            return DayTemplate(focus: "Strength", intensity: .moderate, title: "General Strength", blocks: [
                .init(name: "Warm-up", detail: "8 min bike/jog", targetPace: nil),
                .init(name: "Lift", detail: "Squat, RDL, step-ups — 3x6 @ controlled", targetPace: nil),
                .init(name: "Core", detail: "3 rounds anti-rotation work", targetPace: nil),
                .init(name: "Cooldown", detail: "Mobility", targetPace: nil)
            ])
        case 5:
            return DayTemplate(focus: "Technique", intensity: .low, title: "Technique Drills", blocks: [
                .init(name: "Warm-up", detail: "10 min + drills", targetPace: nil),
                .init(name: "Drills", detail: "Pop-up drills, arm action, landing mechanics", targetPace: nil),
                .init(name: "Cooldown", detail: "Stretch", targetPace: nil)
            ])
        case 6:
            return DayTemplate(focus: "Competition", intensity: .high, title: "Competition / Meet Prep", blocks: [
                .init(name: "Warm-up", detail: "Full meet warm-up routine", targetPace: nil),
                .init(name: "Jump attempts", detail: "6-10 competitive attempts at 90-100%", targetPace: nil)
            ])
        default:
            return DayTemplate(focus: "Recovery", intensity: .low, title: "Rest & Recovery", blocks: [
                .init(name: "Optional", detail: "Light walk + full stretch routine", targetPace: nil)
            ])
        }
    }

    private static func throwsGroup(phase: PlanPhase, day: Int) -> DayTemplate {
        switch day {
        case 1:
            return DayTemplate(focus: "Heavy Throws", intensity: .high, title: "Heavy Implement Day", blocks: [
                .init(name: "Warm-up", detail: "Thrower's warm-up + med ball work", targetPace: nil),
                .init(name: "Heavy throws", detail: "\(repCount(phase, base: 12)) throws w/ heavy implement", targetPace: nil),
                .init(name: "Cooldown", detail: "Stretch", targetPace: nil)
            ])
        case 2:
            return DayTemplate(focus: "Technique", intensity: .moderate, title: "Technical Drills", blocks: [
                .init(name: "Warm-up", detail: "10 min + footwork patterns", targetPace: nil),
                .init(name: "Drills", detail: "Power position + full movement rehearsals, no implement", targetPace: nil),
                .init(name: "Light throws", detail: "8 throws @ 60% focus on positions", targetPace: nil),
                .init(name: "Cooldown", detail: "Mobility", targetPace: nil)
            ])
        case 3:
            return DayTemplate(focus: "Power", intensity: .high, title: "Power Development", blocks: [
                .init(name: "Warm-up", detail: "8 min + dynamic work", targetPace: nil),
                .init(name: "Olympic work", detail: "Hang cleans / trap-bar jumps 4x3", targetPace: nil),
                .init(name: "Throwing", detail: "10 med-ball rotational throws", targetPace: nil),
                .init(name: "Cooldown", detail: "Stretch", targetPace: nil)
            ])
        case 4:
            return DayTemplate(focus: "Technique", intensity: .moderate, title: "Full Throws", blocks: [
                .init(name: "Warm-up", detail: "Full warm-up", targetPace: nil),
                .init(name: "Full throws", detail: "\(repCount(phase, base: 15)) competition-implement throws", targetPace: nil),
                .init(name: "Cooldown", detail: "Stretch + video review", targetPace: nil)
            ])
        case 5:
            return DayTemplate(focus: "Speed Throws", intensity: .moderate, title: "Light / Speed Implements", blocks: [
                .init(name: "Warm-up", detail: "10 min", targetPace: nil),
                .init(name: "Speed throws", detail: "12 throws w/ light implement, max intent", targetPace: nil),
                .init(name: "Cooldown", detail: "Mobility", targetPace: nil)
            ])
        case 6:
            return DayTemplate(focus: "Competition", intensity: .high, title: "Meet / Meet Prep", blocks: [
                .init(name: "Warm-up", detail: "Full meet routine", targetPace: nil),
                .init(name: "Attempts", detail: "6 competition attempts", targetPace: nil)
            ])
        default:
            return DayTemplate(focus: "Recovery", intensity: .low, title: "Rest & Recovery", blocks: [
                .init(name: "Optional", detail: "Light movement + stretch", targetPace: nil)
            ])
        }
    }

    private static func repCount(_ phase: PlanPhase, base: Int) -> Int {
        switch phase {
        case .base: return base
        case .build: return base + 1
        case .peak: return base
        case .taper: return max(2, base / 2)
        }
    }
}
