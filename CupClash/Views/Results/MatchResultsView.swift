import SwiftUI

struct MatchResultsView: View {
    let result: MatchResult
    @Environment(AppRouter.self) private var router
    @Environment(GameSettings.self) private var settings

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        Text(result.playerWon ? "Victory" : (result.winner == nil ? "Complete" : "Defeat"))
                            .font(CupClashTheme.titleFont)
                            .foregroundStyle(result.playerWon ? CupClashTheme.gold : CupClashTheme.textPrimary)
                        Text(winnerLine)
                            .foregroundStyle(CupClashTheme.textSecondary)
                    }
                    .padding(.top, 12)

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            stat("Winner", winnerLine)
                            stat("Cups left", "You \(result.playerCupsRemaining) • Rival \(result.opponentCupsRemaining)")
                            stat("Shots", "\(result.playerMakes)/\(result.playerShots)")
                            stat("Accuracy", AccuracyMath.formatted(made: result.playerMakes, attempted: result.playerShots))
                            stat("Best streak", "\(result.bestStreak)")
                        }
                    }

                    GlassPanel {
                        RewardSummaryView(result: result)
                    }

                    PrimaryButton(title: "Rematch", symbol: "arrow.clockwise") {
                        router.pop()
                        router.start(result.configuration)
                    }
                    SecondaryButton(title: "Home", symbol: "house.fill") {
                        router.popToHome()
                    }
                    CreatorCredit(compact: true)
                }
                .padding(20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if result.rewards.totalCoins > 0 {
                AudioManager.shared.play(.coins)
                HapticManager.shared.coins()
            }
            if result.rewards.levelsGained > 0 {
                AudioManager.shared.play(.levelUp)
                HapticManager.shared.levelUp()
            }
        }
    }

    private var winnerLine: String {
        if result.playerWon { return result.configuration.playerName }
        if let winner = result.winner {
            return winner == .player ? result.configuration.playerName : result.configuration.opponentName
        }
        return "No winner"
    }

    private func stat(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(CupClashTheme.textSecondary)
            Spacer()
            Text(value).fontWeight(.bold)
        }
        .font(.system(.body, design: .rounded))
    }
}
