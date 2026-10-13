import Foundation

enum PlanAdjustmentEngine {
    static func adjust(day: PlanDay, flag: HeatFlag, daysToRace: Int?) -> PlanDay {
        var d = day
        switch flag {
        case .green:
            break
        case .yellow:
            d.workRestRatio = "2:1"
            d.extraBreaksPerHour = 3
            d.note = "Heat-adjusted: extra breaks added — NATA Yellow Flag"
        case .orange:
            d.workRestRatio = "1:1"
            if d.intensity == .high {
                d.title = "Technique day (heat-adjusted)"
                d.note = "Speed session moved to 7 AM or swapped to drills — NATA Orange Flag"
            } else {
                d.note = "Heat-adjusted work:rest 1:1 — NATA Orange Flag"
            }
        case .red, .black:
            d.indoorOnly = true
            d.title = "Indoor day (heat-adjusted)"
            d.note = "Outdoor practice suspended — heat flag \(flag.rawValue). Follow your school or district heat policy."
        }
        if let days = daysToRace, days <= 7, days >= 0, d.intensity == .high {
            d.volumeScale = 0.6
            d.note = [d.note, "Taper week: high-intensity volume reduced 40%."].compactMap { $0 }.joined(separator: " ")
        }
        return d
    }
}
