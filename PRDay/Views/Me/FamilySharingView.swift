import SwiftUI
import SwiftData
import PhotosUI

struct FamilySharingView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = FamilySharingViewModel()

    var body: some View {
        Form {
            if !viewModel.iCloudAvailable {
                Section {
                    Label("iCloud is not signed in. Family sharing needs iCloud (Settings → Apple ID → iCloud).", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.prHeatYellow)
                }
            }
            Section {
                Button {
                    Task { await viewModel.createShare(context: context) }
                } label: {
                    Label("Create Weekly Report Share", systemImage: "link.badge.plus")
                }
                if let url = viewModel.shareURL {
                    ShareLink(item: url) {
                        Label("Send Invite Link", systemImage: "paperplane")
                    }
                }
                if let error = viewModel.errorText {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            } header: {
                Text("Invite a Parent")
            } footer: {
                Text("Parents get a read-only weekly report: workouts completed, new PRs, and streak. Heart-rate data stays private and is never shared.")
            }

            Section("This Week") {
                if let summary = viewModel.lastSummary {
                    LabeledContent("Workouts", value: "\(summary.completedCount)")
                    LabeledContent("New PRs", value: "\(summary.newPRCount)")
                    LabeledContent("Streak", value: "\(summary.streak) days")
                    Text(summary.focusText).font(.caption)
                } else {
                    Text("Create a share to generate this week's report.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Family Sharing")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.fetchSharedReports() }
    }
}

struct ParentHomeView: View {
    @StateObject private var viewModel = FamilySharingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.reports.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Waiting for your athlete's first report")
                                .font(.headline)
                            Text("Ask your athlete to send the invite link from PRDay → Me → Family Sharing. Reports arrive every Sunday at 7 PM.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                        .padding(.horizontal, 24)
                    }
                    ForEach(viewModel.reports) { report in
                        ReportCardView(payload: report, watermark: false)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 4)
                            .frame(maxWidth: 380)
                    }
                    DisclaimerFooter()
                }
                .padding()
            }
            .background(.prBase)
            .navigationTitle("PRDay Family")
            .task { await viewModel.fetchSharedReports() }
            .refreshable { await viewModel.fetchSharedReports() }
        }
        .preferredColorScheme(.light)
    }
}
