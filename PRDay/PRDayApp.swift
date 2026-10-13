import SwiftUI
import SwiftData

@main
struct PRDayApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            AthleteProfile.self,
            WorkoutSession.self,
            PersonalRecord.self,
            StreakState.self,
            StreakEvent.self,
            WeeklyReport.self,
            MeetChecklistState.self
        ])
        do {
            let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            let config = ModelConfiguration(schema: schema)
            container = (try? ModelContainer(for: schema, configurations: [config])) ?? {
                fatalError("Unable to create local storage: \(error)")
            }()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
                .tint(.prOrange)
        }
    }
}
