import Foundation
import HealthKit

final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestReadAuthorization() async -> Bool {
        guard Self.isAvailable else { return false }
        guard let hrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return false }
        return await withCheckedContinuation { cont in
            store.requestAuthorization(toShare: Set<HKSampleType>(), read: [hrType, stepType]) { ok, _ in
                cont.resume(returning: ok)
            }
        }
    }

    func latestRestingHeartRate() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        return await latestValue(type: type, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    private func latestValue(type: HKQuantityType, unit: HKUnit) async -> Double? {
        await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: nil, options: .discreteMostRecent) { _, stats, _ in
                let value = stats?.mostRecentQuantity()?.doubleValue(for: unit)
                cont.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
