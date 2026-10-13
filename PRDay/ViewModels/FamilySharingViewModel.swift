import Foundation
import SwiftData
import Combine
import CloudKit

@MainActor
final class FamilySharingViewModel: ObservableObject {
    @Published var shareURL: URL?
    @Published var reports: [ReportPayload] = []
    @Published var errorText: String?
    @Published var lastSummary: ParentReportService.WeekSummary?
    @Published var iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil

    func createShare(context: ModelContext) async {
        errorText = nil
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let records = (try? context.fetch(FetchDescriptor<PersonalRecord>())) ?? []
        let allDays = sessions.filter { $0.completed }.map { $0.date }
        let streak = StreakEngine.currentStreak(sessionDays: allDays, makeupDays: [])
        let summary = ParentReportService.shared.buildSummary(sessions: sessions, records: records, streak: streak, planDays: [])
        lastSummary = summary
        let name = UserDefaults.standard.string(forKey: "athlete.name") ?? "Your athlete"
        let payload = ReportPayload(
            recordID: nil,
            athleteName: name,
            weekStart: Date.now,
            completedCount: summary.completedCount,
            plannedCount: summary.plannedCount,
            newPRCount: summary.newPRCount,
            streak: summary.streak,
            focusText: summary.focusText
        )
        do {
            let (share, _) = try await CloudSyncService.shared.createFamilyShare(payload: payload)
            if let url = share.url {
                shareURL = url
            }
        } catch {
            errorText = "Could not create the family share. Check that iCloud is signed in (Settings → Apple ID → iCloud)."
        }
    }

    func fetchSharedReports() async {
        guard let profileIsParent = UserDefaults.standard.object(forKey: "parent.mode") as? Bool, profileIsParent else { return }
        do {
            reports = try await CloudSyncService.shared.fetchSharedReports()
        } catch {
            errorText = "Could not load shared reports."
        }
    }
}
