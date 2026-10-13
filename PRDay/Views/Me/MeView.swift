import SwiftUI
import SwiftData

struct MeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var purchase = PurchaseManager.shared
    @State private var profile: AthleteProfile?
    @State private var showPaywall = false
    @State private var goalRace = ""
    @State private var raceDate: Date = Date.now.addingTimeInterval(7 * 86400)
    @State private var showHealthInfo = false
    @State private var healthEnabled = false
    @State private var restingHR: Double?
    @AppStorage("notify.daily") private var dailyNotify = true
    @AppStorage("notify.sunday") private var sundayNotify = true
    @AppStorage("athlete.name") private var athleteName = ""

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                proSection
                familySection
                formSection
                healthSection
                notificationSection
                legalSection
                aboutSection
            }
            .navigationTitle("Me")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showHealthInfo) { HealthKitInfoView() }
            .onAppear {
                profile = AthleteProfileBox.load(context: context)
                goalRace = profile?.goalRace ?? ""
                if let d = profile?.raceDate { raceDate = d }
                if athleteName.isEmpty { athleteName = "" }
            }
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            TextField("Your name", text: $athleteName)
            Picker("Event group", selection: Binding(
                get: { profile?.eventGroup ?? .sprints },
                set: { newValue in
                    profile?.eventGroup = newValue
                    try? context.save()
                })) {
                ForEach(EventGroup.allCases) { g in Text(g.displayName).tag(g) }
            }
            Picker("Level", selection: Binding(
                get: { profile?.level ?? .firstSeason },
                set: { newValue in
                    profile?.level = newValue
                    try? context.save()
                })) {
                ForEach(AthleteLevel.allCases) { l in Text(l.rawValue).tag(l) }
            }
            TextField("Goal race (e.g. State Finals 1600m)", text: $goalRace)
            DatePicker("Race date", selection: $raceDate, displayedComponents: .date)
                .onChange(of: raceDate) { _, new in
                    profile?.raceDate = new
                    try? context.save()
                }
            Button("Save Goal") {
                profile?.goalRace = goalRace
                profile?.raceDate = raceDate
                try? context.save()
            }
        }
    }

    private var proSection: some View {
        Section {
            if purchase.isPro {
                Label("PRDay Pro active", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.prHeatGreen)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "crown.fill")
                        .foregroundStyle(.prOrange)
                }
            }
            Button("Restore Purchases") {
                Task { await purchase.restorePurchases() }
            }
        } footer: {
            if let error = purchase.loadError {
                Text(error)
            }
        }
    }

    private var familySection: some View {
        Section("Family") {
            NavigationLink {
                FamilySharingView()
            } label: {
                Label("Parent Weekly Report", systemImage: "person.2")
            }
            if !purchase.isPro {
                Text("Weekly reports are a Pro feature.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var formSection: some View {
        Section("AI Tools") {
            NavigationLink {
                FormCheckView()
            } label: {
                Label("AI Form Check", systemImage: "camera.viewfinder")
            }
            NavigationLink {
                AISettingsView()
            } label: {
                Label("AI Settings (BYO Key)", systemImage: "key.fill")
            }
        }
    }

    private var healthSection: some View {
        Section {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HealthKit Integration")
                        .font(.headline)
                    Text("Read resting heart rate from Apple Health via HealthKit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showHealthInfo = true
                } label: {
                    Text("Learn More")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
            Toggle("Sync Resting Heart Rate from HealthKit", isOn: $healthEnabled)
                .onChange(of: healthEnabled) { _, enabled in
                    if enabled {
                        Task {
                            let ok = await HealthKitService.shared.requestReadAuthorization()
                            if ok {
                                restingHR = await HealthKitService.shared.latestRestingHeartRate()
                            } else {
                                healthEnabled = false
                            }
                        }
                    }
                }
            if let hr = restingHR {
                Text("Latest resting HR: \(Int(hr)) bpm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text("Apple Health (HealthKit)")
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("This app uses the HealthKit framework to read resting heart rate from the Apple Health app. This requires your explicit permission. No health data is written or shared.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var notificationSection: some View {
        Section("Notifications") {
            Toggle("Daily plan reminder (7 AM)", isOn: $dailyNotify)
                .onChange(of: dailyNotify) { _, on in
                    if on {
                        NotificationService.scheduleDailyReminder(hour: 7)
                    } else {
                        NotificationService.cancelDailyReminder()
                    }
                }
            Toggle("Sunday report reminder (7 PM)", isOn: $sundayNotify)
                .onChange(of: sundayNotify) { _, on in
                    if on {
                        NotificationService.scheduleSundayReport()
                    } else {
                        NotificationService.cancelSundayReport()
                    }
                }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            Link(destination: Theme.privacyURL) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: Theme.termsURL) {
                Label("Terms of Use", systemImage: "doc.text")
            }
            Link(destination: Theme.supportURL) {
                Label("Support", systemImage: "questionmark.circle")
            }
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
            Link(destination: Theme.appleWeatherLegalURL) {
                HStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                    Text("Weather — Data Source")
                }
            }
        }
    }

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Make every meet a PR Day.")
                    .font(.subheadline.weight(.semibold))
                Text(Theme.disclaimer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(appVersion)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } footer: {
            Text("Weather information provided by Apple Weather.")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}
