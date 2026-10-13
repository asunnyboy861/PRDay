import Foundation
import SwiftData

struct AthleteProfileBox {
    static func load(context: ModelContext) -> AthleteProfile? {
        let descriptor = FetchDescriptor<AthleteProfile>(sortBy: [SortDescriptor(\.createdAt)])
        return try? descriptor.fetchLimited(context: context, limit: 1).first
    }
}

extension FetchDescriptor {
    func fetchLimited(context: ModelContext, limit: Int) throws -> [T] {
        var d = self
        d.fetchLimit = limit
        return try context.fetch(d)
    }
}
