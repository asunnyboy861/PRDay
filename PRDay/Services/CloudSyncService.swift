import Foundation
import CloudKit

struct ReportPayload: Identifiable, Equatable {
    var id: String { recordID ?? weekStart.description }
    var recordID: String?
    let athleteName: String
    let weekStart: Date
    let completedCount: Int
    let plannedCount: Int
    let newPRCount: Int
    let streak: Int
    let focusText: String
}

final class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    static let containerID = "iCloud.com.zzoutuo.PRDay"

    @Published var iCloudAvailable: Bool = FileManager.default.ubiquityIdentityToken != nil

    private let container: CKContainer
    private let zoneID = CKRecordZone.ID(zoneName: "PRDayFamilyZone", ownerName: CKCurrentUserDefaultName)

    private init() {
        container = CKContainer(identifier: Self.containerID)
    }

    func createFamilyShare(payload: ReportPayload) async throws -> (CKShare, CKRecord) {
        let zone = CKRecordZone(zoneID: zoneID)
        _ = try? await container.privateCloudDatabase.modifyRecordZones(saving: [zone], deleting: [])

        let recordID = CKRecord.ID(recordName: "weekly-\(Int(payload.weekStart.timeIntervalSince1970))", zoneID: zoneID)
        let record = CKRecord(recordType: "WeeklyReport", recordID: recordID)
        record["athleteName"] = payload.athleteName as CKRecordValue
        record["weekStart"] = payload.weekStart as CKRecordValue
        record["completedCount"] = payload.completedCount as CKRecordValue
        record["plannedCount"] = payload.plannedCount as CKRecordValue
        record["newPRCount"] = payload.newPRCount as CKRecordValue
        record["streak"] = payload.streak as CKRecordValue
        record["focusText"] = payload.focusText as CKRecordValue

        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "\(payload.athleteName)'s PRDay Weekly" as CKRecordValue
        share.publicPermission = .none

        _ = try await container.privateCloudDatabase.modifyRecords(saving: [record, share], deleting: [])
        return (share, record)
    }

    func fetchSharedReports() async throws -> [ReportPayload] {
        let db = container.sharedCloudDatabase
        var results: [ReportPayload] = []
        let zones = try await db.allRecordZones()
        for zone in zones {
            let query = CKQuery(recordType: "WeeklyReport", predicate: NSPredicate(value: true))
            let (matches, _) = try await db.records(matching: query, inZoneWith: zone.zoneID)
            for (_, result) in matches {
                if case .success(let record) = result, record.recordType == "WeeklyReport" {
                    results.append(Self.payload(from: record))
                }
            }
        }
        return results.sorted { $0.weekStart > $1.weekStart }
    }

    static func payload(from record: CKRecord) -> ReportPayload {
        ReportPayload(
            recordID: record.recordID.recordName,
            athleteName: record["athleteName"] as? String ?? "Athlete",
            weekStart: record["weekStart"] as? Date ?? Date.now,
            completedCount: record["completedCount"] as? Int ?? 0,
            plannedCount: record["plannedCount"] as? Int ?? 0,
            newPRCount: record["newPRCount"] as? Int ?? 0,
            streak: record["streak"] as? Int ?? 0,
            focusText: record["focusText"] as? String ?? ""
        )
    }
}
