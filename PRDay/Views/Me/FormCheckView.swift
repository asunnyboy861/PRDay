import SwiftUI
import PhotosUI

struct FormCheckView: View {
    @StateObject private var viewModel = FormCheckViewModel()
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Film 6-10 seconds of running from the side — full body in frame, outdoors or well lit.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.quotaText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.prOrange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PhotosPicker(selection: $photoItem, matching: .videos) {
                    VStack(spacing: 10) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 44))
                        Text("Choose Running Video")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 140)
                    .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                if viewModel.isAnalyzing {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Analyzing form — skeleton tracking…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }

                if let error = viewModel.errorText {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.prHeatRed)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.prSurface, in: RoundedRectangle(cornerRadius: 12))
                }

                if let report = viewModel.report {
                    FormReportCard(report: report)
                }
                DisclaimerFooter()
            }
            .padding()
        }
        .background(.prBase)
        .navigationTitle("AI Form Check")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItem, initial: false) { _, item in
            guard item != nil else { return }
            Task { await viewModel.analyze(item: item) }
        }
    }
}

struct FormReportCard: View {
    let report: FormDiagnosisReport

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Diagnosis", systemImage: "stethoscope")
                    .font(.headline)
                Spacer()
                Text(report.source)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            section(title: "Strengths", icon: "hand.thumbsup.fill", color: .prHeatGreen, items: report.strengths)
            section(title: "Fixes & Drills", icon: "wrench.fill", color: .prOrange, items: report.fixes)
            Text(report.safetyNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func section(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(color).frame(width: 6, height: 6).padding(.top, 6)
                    Text(item).font(.callout)
                }
            }
        }
    }
}
