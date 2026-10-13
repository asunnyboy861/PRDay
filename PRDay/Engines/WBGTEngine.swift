import Foundation

struct WBGTResult: Equatable {
    let wbgtF: Double
    let flag: HeatFlag
}

enum WBGTEngine {
    static func compute(tempF: Double, humidity: Double) -> WBGTResult {
        let taC = (tempF - 32) / 1.8
        let es = 6.105 * exp(17.27 * taC / (237.7 + taC))
        let e = es * min(max(humidity, 0), 100) / 100
        let wbgtC = 0.567 * taC + 0.393 * e + 3.94
        let wbgtF = wbgtC * 1.8 + 32
        return WBGTResult(wbgtF: wbgtF, flag: classify(wbgtF: wbgtF))
    }

    static func classify(wbgtF: Double) -> HeatFlag {
        switch wbgtF {
        case ..<82: return .green
        case 82..<87: return .yellow
        case 87..<90: return .orange
        case 90..<92.2: return .red
        default: return .black
        }
    }
}
