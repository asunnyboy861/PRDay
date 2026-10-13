import Foundation
import SwiftUI
import SwiftData
import Combine
import PhotosUI

@MainActor
final class FormCheckViewModel: ObservableObject {
    @Published var isAnalyzing = false
    @Published var report: FormDiagnosisReport?
    @Published var errorText: String?
    @Published var isPro = false
    @Published var quotaText: String
    private var cancellables = Set<AnyCancellable>()
    private let analyzer = FormAnalyzer()
    private let service = FormDiagnosisService.shared

    init(purchaseManager: PurchaseManager = .shared) {
        quotaText = ""
        purchaseManager.$isPro
            .receive(on: RunLoop.main)
            .assign(to: &$isPro)
        refreshQuota()
    }

    func refreshQuota() {
        let (limit, period) = Entitlement.glmQuota(isPro: isPro)
        let used = Entitlement.glmUsedThisPeriod(isPro: isPro)
        if AIConfiguration.hasAnyProviderKey {
            quotaText = "Unlimited with your own AI key"
        } else if isPro {
            quotaText = "\(max(limit - used, 0)) of \(limit) remaining this \(period)"
        } else {
            quotaText = "\(max(limit - used, 0)) of \(limit) remaining this \(period) — Pro gives 8/month"
        }
    }

    func analyze(item: PhotosPickerItem?) async {
        guard let item, let videoURL = try? await item.loadTransferable(type: URL.self) else {
            errorText = "Could not load the video. Try recording again."
            return
        }
        await analyze(url: videoURL)
    }

    func analyze(url: URL) async {
        guard Entitlement.canRunGLM(isPro: isPro) || AppleIntelligenceGate.isAvailable || AIConfiguration.hasAnyProviderKey else {
            errorText = "You're out of free analyses this week. Upgrade to Pro for 8/month, or add your own AI key for unlimited."
            refreshQuota()
            return
        }
        isAnalyzing = true
        errorText = nil
        defer { isAnalyzing = false }
        do {
            async let features = analyzer.extractFeatures(from: url)
            async let jpegs = analyzer.annotatedFrameJPEGs(from: url)
            let (f, j) = try await (features, jpegs)
            report = await service.diagnose(frames: f, annotatedJPEGs: j, isPro: isPro, profiles: AIProfileManager.shared)
            refreshQuota()
        } catch {
            errorText = error.localizedDescription
        }
        try? FileManager.default.removeItem(at: url)
    }
}
