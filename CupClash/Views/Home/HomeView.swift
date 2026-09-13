import SwiftUI

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 6) {
                        Text(AppConstants.displayName)
                            .font(CupClashTheme.titleFont)
                            .foregroundStyle(CupClashTheme.neonGradient())
                        Text(AppConstants.subtitle)
                            .font(CupClashTheme.subtitleFont)
                            .foregroundStyle(CupClashTheme.textSecondary)
                    }
                    .padding(.top, 12)
                    .accessibilityElement(children: .combine)

                    GlassPanel {
                        PlayerHeaderView(profile: profile)
                    }

                    ArcadeHeroScene(reducedMotion: settings.reducedMotion)

                    ModeCardView(
                        title: GameMode.quickMatch.title,
                        detail: GameMode.quickMatch.detail,
                        symbol: GameMode.quickMatch.symbolName,
                        emphasized: true
                    ) {
                        router.push(.matchSetup(.quickMatch))
                    }

                    ModeCardView(
                        title: GameMode.passAndPlay.title,
                        detail: GameMode.passAndPlay.detail,
                        symbol: GameMode.passAndPlay.symbolName
                    ) {
                        router.push(.matchSetup(.passAndPlay))
                    }

                    ModeCardView(
                        title: GameMode.practice.title,
                        detail: GameMode.practice.detail,
                        symbol: GameMode.practice.symbolName
                    ) {
                        router.push(.practice)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        miniButton("Locker", symbol: "tshirt.fill") { router.push(.locker) }
                        miniButton("Profile", symbol: "person.crop.circle") { router.push(.profile) }
                        miniButton("How to Play", symbol: "questionmark.circle") { router.push(.howToPlay) }
                        miniButton("Settings", symbol: "gearshape.fill") { router.push(.settings) }
                    }

                    CreatorCredit(compact: true)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func miniButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            AudioManager.shared.play(.button)
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.title2)
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(CupClashTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: CupClashTheme.radiusM, style: .continuous)
                    .fill(CupClashTheme.navyPanel.opacity(0.88))
            )
        }
        .accessibilityLabel(title)
    }
}

struct ArcadeHeroScene: View {
    var reducedMotion = false
    @State private var bounce = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [CupClashTheme.violet.opacity(0.35), CupClashTheme.navy], startPoint: .top, endPoint: .bottom))
            HStack(spacing: 28) {
                VStack(spacing: -8) {
                    cup
                    HStack(spacing: 8) { cup; cup }
                    HStack(spacing: 8) { cup; cup; cup }
                }
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .shadow(color: CupClashTheme.cyan, radius: 8)
                    .offset(y: bounce ? -18 : 10)
            }
        }
        .frame(height: 118)
        .onAppear {
            guard !reducedMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
        .accessibilityLabel("Decorative cups and bouncing ball")
    }

    private var cup: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(CupClashTheme.cyan.opacity(0.9))
            .frame(width: 22, height: 26)
    }
}
