import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var profile: AthleteProfile?
    @State private var parentMode = false

    var body: some View {
        Group {
            if let profile, profile.onboardingCompleted {
                if parentMode {
                    ParentHomeView()
                } else {
                    MainTabView()
                }
            } else {
                OnboardingView(onComplete: {
                    profile = AthleteProfileBox.load(context: context)
                    parentMode = UserDefaults.standard.bool(forKey: "parent.mode")
                })
            }
        }
        .onAppear {
            profile = AthleteProfileBox.load(context: context)
            parentMode = UserDefaults.standard.bool(forKey: "parent.mode")
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "flame.fill") }
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
            PRsView()
                .tabItem { Label("PRs", systemImage: "chart.line.uptrend.xyaxis") }
            MeView()
                .tabItem { Label("Me", systemImage: "person.fill") }
        }
        .tint(.prOrange)
    }
}
