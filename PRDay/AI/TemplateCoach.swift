import Foundation

enum TemplateCoach {
    static func answer(question: String, completedThisWeek: Int, streak: Int, nextPRDelta: String?, planFocus: String?) -> String {
        let q = question.lowercased()
        var parts: [String] = []
        if q.contains("tired") || q.contains("sore") || q.contains("rest") {
            parts.append("With a \(streak)-day streak, protect recovery: keep tomorrow's session low intensity and prioritize 8+ hours of sleep.")
        }
        if q.contains("pr") || q.contains("faster") || q.contains("improve") {
            if let delta = nextPRDelta {
                parts.append("You're \(delta) from your PR. The fastest path: nail the interval paces on your plan and don't skip the technique day.")
            } else {
                parts.append("Log a mark at your next meet or time trial — I'll track exactly how far you are from each PR.")
            }
        }
        if q.contains("heat") || q.contains("weather") || q.contains("hot") {
            parts.append("Check the heat flag at the top of Today. On orange or red flags, move hard sessions to early morning and add the listed rest breaks.")
        }
        if q.contains("plan") || q.contains("workout") {
            if let focus = planFocus {
                parts.append("Today's plan focuses on \(focus). Complete it at the listed paces — consistency beats intensity.")
            } else {
                parts.append("Open Today for this week's focus. Pro unlocks the full 12-week plan library.")
            }
        }
        parts.append("This week: \(completedThisWeek) workout\(completedThisWeek == 1 ? "" : "s") logged. \(streak > 0 ? "Streak: \(streak) days." : "")")
        if parts.count == 1 {
            parts.insert("I can read your training data and help with pacing, heat adjustments, recovery, and plan questions. Try asking about your PR gap or today's focus.", at: 0)
        }
        return parts.prefix(3).joined(separator: "\n\n")
    }
}
