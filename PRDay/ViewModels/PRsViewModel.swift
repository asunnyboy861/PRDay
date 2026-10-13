import Foundation
import SwiftData
import Combine

@MainActor
final class PRsViewModel: ObservableObject {
    @Published var records: [PersonalRecord] = []
    @Published var selectedEvent: String?
    @Published var isPro = false
    @Published var freeEventLimitReached = false
    private var cancellables = Set<AnyCancellable>()

    static let freeEventLimit = 3

    init(purchaseManager: PurchaseManager = .shared) {
        purchaseManager.$isPro
            .receive(on: RunLoop.main)
            .assign(to: &$isPro)
    }

    func load(context: ModelContext, group: EventGroup) {
        records = ((try? context.fetch(FetchDescriptor<PersonalRecord>(sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]))) ?? [])
        if selectedEvent == nil {
            selectedEvent = group.events.first
        }
        if !isPro {
            let used = usedEvents
            if let sel = selectedEvent, !used.contains(sel), used.count >= Self.freeEventLimit {
                freeEventLimitReached = true
            } else {
                freeEventLimitReached = false
            }
        }
    }

    var usedEvents: [String] {
        Array(Set(records.map { $0.event })).sorted()
    }

    var selectedRecords: [PersonalRecord] {
        guard let event = selectedEvent else { return [] }
        return records.filter { $0.event == event }.sorted { $0.achievedAt > $1.achievedAt }
    }

    var bestRecord: PersonalRecord? {
        guard let event = selectedEvent else { return nil }
        let isTime = event.contains("m")
        let valid = records.filter { $0.event == event && !$0.windAssisted }
        return isTime ? valid.min { $0.mark < $1.mark } : valid.max { $0.mark < $1.mark }
    }

    func canAdd(event: String) -> Bool {
        if isPro { return true }
        return usedEvents.contains(event) || usedEvents.count < Self.freeEventLimit
    }

    func addRecord(context: ModelContext, event: String, mark: Double, windAssisted: Bool) {
        let record = PersonalRecord()
        record.event = event
        record.mark = mark
        record.achievedAt = Date.now
        record.windAssisted = windAssisted
        record.isTime = event.contains("m") && !event.contains("Jump")
        context.insert(record)
        try? context.save()
        records.append(record)
    }
}
