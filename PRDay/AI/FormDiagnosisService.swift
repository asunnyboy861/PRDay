import Foundation

struct FormDiagnosisReport: Identifiable, Equatable {
    var id: UUID = UUID()
    let strengths: [String]
    let fixes: [String]
    let safetyNote: String
    let source: String
    let createdAt: Date = Date.now
}

final class FormDiagnosisService {
    static let shared = FormDiagnosisService()

    @MainActor
    func diagnose(frames: [PoseFeatures], annotatedJPEGs: [String], isPro: Bool, profiles: AIProfileManager) async -> FormDiagnosisReport {
        let features = FormAnalyzer.summarize(frames: frames)
        let backend = AICoachRouter.route(.formDiagnosis, isPro: isPro, profiles: profiles)
        let system = """
        You are an elite track & field form coach. Analyze the annotated skeleton frames \
        (knee angle, trunk lean, ground contact). Output: 3 strengths, 3 fixes with drills, \
        one-line safety note. Keep under 180 words.
        """
        let user = """
        Measured averages from on-device pose analysis: knee angle \(Int(features.kneeAngleDeg))°, \
        trunk lean \(Int(features.trunkLeanDeg))° from vertical, hip drop \(Int(features.hipDropDeg))°. \
        Provide the diagnosis.
        """
        switch backend {
        case .byoProvider(let service):
            do {
                let text = try await service.chat(system: system, user: user, imagesJPEGBase64: annotatedJPEGs)
                Entitlement.recordGLMRun(isPro: isPro)
                return Self.parse(text: text, source: "\(profiles.activeProvider?.label ?? "Custom") AI")
            } catch {
                return Self.onDeviceReport(features: features)
            }
        case .glmProxy:
            do {
                let text = try await GLMProxyService.shared.chat(system: system, user: user, imagesJPEGBase64: annotatedJPEGs)
                Entitlement.recordGLMRun(isPro: isPro)
                return Self.parse(text: text, source: "PRDay AI")
            } catch {
                return Self.onDeviceReport(features: features)
            }
        default:
            return Self.onDeviceReport(features: features)
        }
    }

    static func parse(text: String, source: String) -> FormDiagnosisReport {
        let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var strengths: [String] = []
        var fixes: [String] = []
        var safety: [String] = []
        var current = 0
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("strength") { current = 1; continue }
            if lower.contains("fix") || lower.contains("improve") { current = 2; continue }
            if lower.contains("safety") || lower.contains("note") { current = 3; continue }
            let clean = line.replacingOccurrences(of: "^[-*•\\d.\\s]+", with: "", options: .regularExpression)
            guard !clean.isEmpty else { continue }
            switch current {
            case 1: strengths.append(clean)
            case 2: fixes.append(clean)
            case 3: safety.append(clean)
            default: strengths.append(clean)
            }
        }
        return FormDiagnosisReport(
            strengths: Array(strengths.prefix(3)),
            fixes: Array(fixes.prefix(3)),
            safetyNote: safety.first ?? "Stop if you feel pain. For training guidance only.",
            source: source
        )
    }

    static func onDeviceReport(features: PoseFeatures) -> FormDiagnosisReport {
        var strengths: [String] = []
        var fixes: [String] = []
        if features.kneeAngleDeg >= 140 {
            strengths.append("Good knee extension through the running cycle.")
        } else {
            fixes.append("Increase knee drive: 3 x 10 wall-supported high knees before your next run.")
        }
        if features.trunkLeanDeg >= 4 && features.trunkLeanDeg <= 12 {
            strengths.append("Effective forward trunk lean from the ankles.")
        } else if features.trunkLeanDeg < 4 {
            fixes.append("Lean slightly from the ankles, not the waist — practice 4 x 20m lean-in starts.")
        } else {
            fixes.append("Reduce over-striding: shorter, quicker steps — 5 x 30m cadence strides.")
        }
        if features.hipDropDeg < 6 {
            strengths.append("Stable hips through contact.")
        } else {
            fixes.append("Add hip stability work: 3 x 10 single-leg glute bridges per side.")
        }
        return FormDiagnosisReport(
            strengths: strengths.isEmpty ? ["Consistent frame-to-frame mechanics."] : strengths,
            fixes: fixes.isEmpty ? ["Keep logging videos weekly to track changes."] : fixes,
            safetyNote: "Offline analysis from on-device pose tracking. Stop if you feel pain.",
            source: "On-device analysis"
        )
    }
}
