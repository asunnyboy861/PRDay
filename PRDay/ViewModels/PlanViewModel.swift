import Foundation
import Combine
import SwiftData

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var weeks: [PlanWeek] = []
    @Published var selectedWeek = 1
    @Published var isPro = false
    private var cancellables = Set<AnyCancellable>()

    init(purchaseManager: PurchaseManager = .shared) {
        purchaseManager.$isPro
            .receive(on: RunLoop.main)
            .assign(to: &$isPro)
    }

    func load(context: ModelContext) {
        guard let profile = AthleteProfileBox.load(context: context) else { return }
        let records = (try? context.fetch(FetchDescriptor<PersonalRecord>())) ?? []
        var bestRuns: [String: Double] = [:]
        for r in records where r.isTime && !r.windAssisted {
            let current = bestRuns[r.event]
            if current == nil || r.mark < current! {
                bestRuns[r.event] = r.mark
            }
        }
        weeks = PlanEngine.generate(profile: profile, bestRuns: bestRuns)
    }

    var currentPhase: PlanPhase? {
        weeks.first { $0.week == selectedWeek }?.phase
    }

    func isLocked(week: Int) -> Bool {
        !isPro && week > 1
    }
}
