import SwiftUI
import SwiftData

struct AskCoachView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AskCoachViewModel()
    @StateObject private var purchase = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScrollView {
                    if let answer = viewModel.answer {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Coach", systemImage: "figure.run")
                                .font(.headline)
                                .foregroundStyle(.prOrange)
                            Text(answer)
                                .font(.callout)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DisclaimerFooter()
                        }
                        .padding()
                        .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
                    } else if !viewModel.isLoading {
                        VStack(spacing: 10) {
                            Image(systemName: "bubble.left.and.text.bubble.right")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("Ask about your training — pacing, heat, recovery, or your plan.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            if purchase.isPro {
                                Text("Pro: unlimited coach questions.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 40)
                    }
                    if viewModel.isLoading {
                        ProgressView("Coach is thinking…")
                            .padding()
                    }
                }
                HStack(spacing: 8) {
                    TextField("Ask your coach…", text: $viewModel.question, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(12)
                        .background(.prSurface, in: RoundedRectangle(cornerRadius: 14))
                    Button {
                        Task { await viewModel.ask(context: context) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                    }
                    .disabled(viewModel.question.isEmpty || viewModel.isLoading)
                }
            }
            .padding()
            .background(.prBase)
            .navigationTitle("Ask Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
