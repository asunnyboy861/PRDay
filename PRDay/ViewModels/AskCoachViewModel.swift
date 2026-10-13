import Foundation
import SwiftData
import Combine

@MainActor
final class AskCoachViewModel: ObservableObject {
    @Published var question = ""
    @Published var answer: String?
    @Published var isLoading = false
    @Published var isPro = false
    private var cancellables = Set<AnyCancellable>()

    init(purchaseManager: PurchaseManager = .shared) {
        purchaseManager.$isPro
            .receive(on: RunLoop.main)
            .assign(to: &$isPro)
    }

    func ask(context: ModelContext) async {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        answer = nil

        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let cal = Calendar.current
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date.now)) ?? Date.now
        let completedThisWeek = sessions.filter { $0.completed && $0.date >= weekStart }.count
        let allDays = sessions.filter { $0.completed }.map { $0.date }
        let streak = StreakEngine.currentStreak(sessionDays: allDays, makeupDays: [])

        let backend = AICoachRouter.route(.chatQA, isPro: isPro, profiles: AIProfileManager.shared)
        let system = "You are a concise high-school track & field coach. Answer in under 120 words. Reference the athlete's data when relevant. For training guidance only, not medical advice."
        switch backend {
        case .appleOnDevice:
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) {
                answer = (try? await AppleIntelligenceService.chat(system: system, user: contextLine(completed: completedThisWeek, streak: streak) + "\n\nQuestion: \(q)")) ?? templateAnswer(q, completedThisWeek, streak)
                return
            }
            #endif
            answer = templateAnswer(q, completedThisWeek, streak)
        case .byoProvider(let service):
            answer = (try? await service.chat(system: system, user: contextLine(completed: completedThisWeek, streak: streak) + "\n\nQuestion: \(q)", imagesJPEGBase64: [])) ?? templateAnswer(q, completedThisWeek, streak)
        case .template, .upsell, .glmProxy:
            answer = templateAnswer(q, completedThisWeek, streak)
        }
    }

    private func contextLine(completed: Int, streak: Int) -> String {
        "Athlete context: \(completed) workouts completed this week, current streak \(streak) days."
    }

    private func templateAnswer(_ q: String, _ completed: Int, _ streak: Int) -> String {
        TemplateCoach.answer(question: q, completedThisWeek: completed, streak: streak, nextPRDelta: nil, planFocus: nil)
    }
}
