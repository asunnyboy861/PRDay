import SwiftUI
import UserNotifications

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var viewModel = OnboardingViewModel()
    @State private var notificationsGranted = false

    var body: some View {
        NavigationStack {
            switch viewModel.step {
            case .hero: hero
            case .role: role
            case .group: group
            case .level: level
            case .permissions: permissions
            case .done: done
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "figure.run")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.prOrange)
            Text("MAKE EVERY MEET\nA PR DAY")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
            Text("Track training that adapts — to you, your goals, and the weather.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: "Get Started", systemImage: "arrow.right") {
                viewModel.step = .role
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private var role: some View {
        VStack(spacing: 16) {
            Text("Who are you?")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
            roleCard(title: "I'm an Athlete", subtitle: "Personalized training plans, PR tracking, and AI form checks", icon: "figure.run") {
                viewModel.isParent = false
                viewModel.step = .group
            }
            roleCard(title: "I'm a Parent", subtitle: "See your athlete's weekly progress — zero setup", icon: "person.2.fill") {
                viewModel.isParent = true
                viewModel.step = .permissions
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func roleCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(.prOrange)
                    .frame(width: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(18)
            .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var group: some View {
        VStack(spacing: 20) {
            Text("Pick your event group")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(EventGroup.allCases) { group in
                    Button {
                        viewModel.eventGroup = group
                        viewModel.step = .level
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: group.icon)
                                .font(.system(size: 34))
                            Text(group.displayName)
                                .font(.subheadline.weight(.semibold))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 110)
                        .background(group == viewModel.eventGroup ? Color.prOrange.opacity(0.2) : .prSurface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(group == viewModel.eventGroup ? .prOrange : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(group.displayName)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var level: some View {
        VStack(spacing: 20) {
            Text("Your level")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 40)
            ForEach(AthleteLevel.allCases) { level in
                Button {
                    viewModel.level = level
                    viewModel.step = .permissions
                } label: {
                    HStack {
                        Text(level.rawValue).font(.headline)
                        Spacer()
                        if viewModel.level == level {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.prOrange)
                        }
                    }
                    .padding(18)
                    .background(.prSurface, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(level.rawValue)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var permissions: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sun.max.fill")
                .font(.system(size: 56))
                .foregroundStyle(.prHeatYellow)
            Text(viewModel.isParent ? "One quick setup" : "We check the heat so practice never wrecks you")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("PRDay uses your location for local weather (WBGT heat flags) and sends a daily plan reminder. Parents get the weekly report every Sunday at 7 PM.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: "Allow Weather & Notifications") {
                Task {
                    let _ = await WeatherProvider.shared.refresh()
                    notificationsGranted = await NotificationService.requestAuthorization()
                    viewModel.complete(context: modelContext, notificationsGranted: notificationsGranted)
                }
            }
            .padding(.horizontal, 24)
            Button("Not now") {
                viewModel.complete(context: modelContext, notificationsGranted: false)
            }
            .font(.subheadline)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private var done: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.prHeatGreen)
            Text("Your first week is ready")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
            Text("Today's workout is highlighted on the Today tab.")
                .foregroundStyle(.secondary)
            Spacer()
            PrimaryButton(title: "Start Today's Workout") {
                onComplete()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    @Environment(\.modelContext) private var modelContext
}
