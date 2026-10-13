import Foundation
import SwiftData

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step {
        case hero, role, group, level, permissions, done
    }

    @Published var step: Step = .hero
    @Published var isParent = false
    @Published var eventGroup: EventGroup = .sprints
    @Published var level: AthleteLevel = .firstSeason

    func complete(context: ModelContext, notificationsGranted: Bool) {
        let profile = AthleteProfile()
        profile.eventGroup = eventGroup
        profile.level = level
        profile.onboardingCompleted = true
        profile.isParentMode = isParent
        context.insert(profile)
        try? context.save()
        if notificationsGranted {
            NotificationService.scheduleDailyReminder(hour: 7)
            NotificationService.scheduleSundayReport()
        }
        UserDefaults.standard.set(isParent, forKey: "parent.mode")
        step = .done
    }
}
