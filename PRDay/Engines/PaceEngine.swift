import Foundation

struct TrainingPaces: Equatable {
    let easyPaceSecPerMile: Double
    let thresholdPaceSecPerMile: Double
    let intervalPaceSecPerMile: Double
    let repPaceSecPerMile: Double
}

enum PaceEngine {
    static func riegel(t1Sec: Double, d1Meters: Double, d2Meters: Double) -> Double {
        guard t1Sec > 0, d1Meters > 0, d2Meters > 0 else { return 0 }
        return t1Sec * pow(d2Meters / d1Meters, 1.06)
    }

    static func equivalentTime(prSec: Double, prMeters: Double, targetMeters: Double) -> Double {
        riegel(t1Sec: prSec, d1Meters: prMeters, d2Meters: targetMeters)
    }

    static func trainingPaces(prSec: Double, prMeters: Double) -> TrainingPaces {
        let t1500 = equivalentTime(prSec: prSec, prMeters: prMeters, targetMeters: 1500)
        let t3000 = equivalentTime(prSec: prSec, prMeters: prMeters, targetMeters: 3000)
        let t10k = equivalentTime(prSec: prSec, prMeters: prMeters, targetMeters: 10000)
        let rep = paceSecPerMile(timeSec: t1500, meters: 1500)
        let interval = paceSecPerMile(timeSec: t3000, meters: 3000)
        let threshold = paceSecPerMile(timeSec: t10k, meters: 10000) * 0.98
        let easy = threshold + 105
        return TrainingPaces(
            easyPaceSecPerMile: easy,
            thresholdPaceSecPerMile: threshold,
            intervalPaceSecPerMile: interval,
            repPaceSecPerMile: rep
        )
    }

    static func paceSecPerMile(timeSec: Double, meters: Double) -> Double {
        guard meters > 0 else { return 0 }
        let miles = meters / 1609.344
        return timeSec / miles
    }

    static func formatSeconds(_ sec: Double) -> String {
        guard sec > 0 else { return "--" }
        let total = Int((sec * 100).rounded())
        let hundredths = total % 100
        let whole = total / 100
        let m = whole / 60
        let s = whole % 60
        if m > 0 {
            return String(format: "%d:%02d.%02d", m, s, hundredths)
        }
        return String(format: "%d.%02d", s, hundredths)
    }

    static func formatPace(_ secPerMile: Double) -> String {
        guard secPerMile > 0 else { return "--" }
        let total = Int(secPerMile.rounded())
        return String(format: "%d:%02d /mi", total / 60, total % 60)
    }

    static func formatCountdown(_ sec: Int) -> String {
        String(format: "%d:%02d", max(sec, 0) / 60, max(sec, 0) % 60)
    }
}
