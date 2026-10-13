import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchase = PurchaseManager.shared
    @State private var selectedYearly = true
    @State private var purchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.prOrange)
                    Text("PRDay Pro")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                    Text("Make every meet a PR Day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 10) {
                        featureRow("calendar.badge.clock", "Full 12-week plan library for your event group")
                        featureRow("thermometer.sun.fill", "Weather-adaptive training (WBGT heat flags rewrite your plan)")
                        featureRow("person.2", "Parent weekly report + family sharing")
                        featureRow("chart.line.uptrend.xyaxis", "Unlimited PR tracking — every event")
                        featureRow("camera.viewfinder", "AI form checks — 8/month (or unlimited with your own key)")
                        featureRow("bubble.left.and.text.bubble.right", "Unlimited AI coach answers")
                        featureRow("checklist", "Meet-day checklist")
                        featureRow("sparkles", "Watermark-free PR share cards")
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.prSurface, in: RoundedRectangle(cornerRadius: 18))

                    tierButton(
                        title: "Annual",
                        price: purchase.yearlyProduct.map { $0.displayPrice } ?? "$49.99",
                        period: "per year",
                        note: "7-day free trial · best value",
                        selected: selectedYearly
                    )
                    tierButton(
                        title: "Monthly",
                        price: purchase.monthlyProduct.map { $0.displayPrice } ?? "$7.99",
                        period: "per month",
                        note: "7-day free trial · cancel anytime",
                        selected: !selectedYearly
                    )

                    if let error = purchase.loadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.prHeatRed)
                    }

                    Button {
                        startPurchase()
                    } label: {
                        HStack {
                            if purchasing { ProgressView().tint(.white) }
                            Text(purchase.isPro ? "You're Pro — Thanks!" : "Start Free Trial")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 50)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.prOrange)
                    .disabled(purchasing || purchase.isPro)

                    Button("Restore Purchases") {
                        Task { await purchase.restorePurchases() }
                    }
                    .font(.subheadline)

                    HStack(spacing: 16) {
                        Link("Privacy Policy", destination: Theme.privacyURL)
                        Link("Terms of Use", destination: Theme.termsURL)
                    }
                    .font(.caption2)
                    .padding(.top, 4)

                    Text("PRDay Pro is an auto-renewing subscription. Free trial converts to a paid subscription unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in App Store settings.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .background(.prBase)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task { await purchase.loadProducts() }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.prOrange)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
        }
    }

    private func tierButton(title: String, price: String, period: String, note: String, selected: Bool) -> some View {
        Button {
            selectedYearly = title == "Annual"
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price).font(.title3.weight(.heavy)).monospacedDigit()
                    Text(period).font(.caption2).foregroundStyle(.secondary)
                }
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(.prOrange)
            }
            .padding(14)
            .background(selected ? Color.prOrange.opacity(0.12) : .prSurface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected ? .prOrange : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) \(price) \(period)")
    }

    private func startPurchase() {
        guard !purchase.isPro else { return }
        purchasing = true
        Task {
            let product = selectedYearly ? purchase.yearlyProduct : purchase.monthlyProduct
            if let product {
                let ok = await purchase.purchase(product)
                if ok { dismiss() }
            }
            purchasing = false
        }
    }
}
