import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings
    @State private var showSplash = true

    var body: some View {
        @Bindable var router = router
        ZStack {
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .matchSetup(let mode):
                            MatchSetupView(mode: mode)
                        case .gameplay(let configuration):
                            GameplayView(configuration: configuration)
                        case .results:
                            if let result = router.lastResult {
                                MatchResultsView(result: result)
                            } else {
                                HomeView()
                            }
                        case .practice:
                            PracticeView()
                        case .locker:
                            LockerView()
                        case .profile:
                            ProfileView()
                        case .settings:
                            SettingsView()
                        case .howToPlay:
                            HowToPlayView()
                        case .leaderboards:
                            LeaderboardsView()
                        case .achievements:
                            AchievementsView()
                        case .tournaments:
                            TournamentHubView()
                        case .challenges:
                            ChallengesView()
                        }
                    }
            }
            .tint(CupClashTheme.cyan)

            if showSplash {
                LaunchSplashView {
                    showSplash = false
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

struct LaunchSplashView: View {
    var onFinished: () -> Void
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(GameSettings.self) private var settings
    @State private var ballProgress: CGFloat = 0
    @State private var glow = false

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            VStack(spacing: 18) {
                Image("SplashIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 148, height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(CupClashTheme.cyan.opacity(glow ? 0.75 : 0.28), lineWidth: 2)
                    }
                    .shadow(color: CupClashTheme.cyan.opacity(glow ? 0.55 : 0.18), radius: glow ? 24 : 8)
                    .scaleEffect(glow ? 1 : 0.9)
                    .accessibilityHidden(true)

                Text(AppConstants.displayName)
                    .font(CupClashTheme.titleFont)
                    .foregroundStyle(CupClashTheme.neonGradient())
                    .accessibilityAddTraits(.isHeader)
                Text(AppConstants.subtitle)
                    .font(CupClashTheme.subtitleFont)
                    .foregroundStyle(CupClashTheme.textSecondary)
                ZStack {
                    Capsule()
                        .fill(CupClashTheme.cyan.opacity(glow ? 0.55 : 0.18))
                        .frame(width: 86, height: 108)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .offset(x: -70 + (140 * ballProgress), y: 40 - (90 * ballProgress) + (70 * ballProgress * ballProgress))
                }
                .frame(height: 140)
            }
        }
        .onAppear {
            let reduce = settings.reducedMotion || systemReduceMotion
            if reduce {
                ballProgress = 1
                glow = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: onFinished)
            } else {
                withAnimation(.easeInOut(duration: 1.15)) {
                    ballProgress = 1
                    glow = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + CupClashTheme.splashDuration, execute: onFinished)
            }
        }
        .accessibilityLabel("Cup Clash, Pong Rivals")
    }
}
