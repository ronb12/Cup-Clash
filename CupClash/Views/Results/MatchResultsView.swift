import SwiftUI

struct MatchResultsView: View {
    let result: MatchResult
    @Environment(AppRouter.self) private var router
    @Environment(GameSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var appeared = false

    private var reduceMotion: Bool { settings.reducedMotion || systemReduceMotion }

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 18) {
                    WinnerCelebrationView(result: result, reduceMotion: reduceMotion)
                        .padding(.top, 4)

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            stat("Mode", modeLine)
                            stat("Winner", winnerLine)
                            if result.configuration.mode == .dailyChallenge {
                                stat("Daily score", "\(DailyChallenge.score(makes: result.playerMakes, won: result.playerWon))")
                            }
                            stat("Score", "You \(result.playerMakes) • Rival \(result.opponentMakes)")
                            stat("Cups left", "You \(result.opponentCupsRemaining) • Rival \(result.playerCupsRemaining)")
                            stat("Your shots", "\(result.playerMakes)/\(result.playerShots)")
                            stat("Rival shots", "\(result.opponentMakes)/\(result.opponentShots)")
                            stat("Accuracy", AccuracyMath.formatted(made: result.playerMakes, attempted: result.playerShots))
                            stat("Best streak", "\(result.bestStreak)")
                            if result.configuration.aimAssistActive {
                                stat("Aim assist", "On")
                            }
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 22)
                    .animation(revealAnimation(delay: 0.22), value: appeared)

                    GlassPanel {
                        RewardSummaryView(result: result, animateNumbers: !reduceMotion && appeared)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 22)
                    .animation(revealAnimation(delay: 0.34), value: appeared)

                    Group {
                        if let next = nextTournamentConfiguration {
                            PrimaryButton(title: "Next Round", symbol: "forward.fill", gold: true) {
                                router.replaceGameplay(with: next)
                            }
                        } else if result.configuration.mode == .tournament, !result.playerWon {
                            PrimaryButton(title: "Retry Bracket", symbol: "arrow.clockwise") {
                                TournamentStore.shared.retryWeek()
                                if let opening = TournamentEvent.current().configuration(
                                    round: 1,
                                    playerName: result.configuration.playerName,
                                    aimAssistance: result.configuration.aimAssistance
                                ) {
                                    router.replaceGameplay(with: opening)
                                }
                            }
                        } else if result.configuration.mode == .tournament {
                            PrimaryButton(title: "Tournaments", symbol: "trophy.fill", gold: result.playerWon) {
                                router.popToHome()
                                router.push(.tournaments)
                            }
                        } else if result.configuration.mode == .challenge {
                            PrimaryButton(title: "Challenges", symbol: "flag.checkered") {
                                router.popToHome()
                                router.push(.challenges)
                            }
                            SecondaryButton(title: "Play Again", symbol: "arrow.clockwise") {
                                router.rematch(result.configuration)
                            }
                        } else {
                            PrimaryButton(title: "Rematch", symbol: "arrow.clockwise") {
                                router.rematch(result.configuration)
                            }
                        }
                        SecondaryButton(title: "Home", symbol: "house.fill") {
                            router.popToHome()
                        }
                        CreatorCredit(compact: true)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                    .animation(revealAnimation(delay: 0.48), value: appeared)
                }
                .padding(20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            appeared = true
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

    private func revealAnimation(delay: Double) -> Animation {
        if reduceMotion {
            return .easeOut(duration: 0.01)
        }
        return .spring(duration: 0.48, bounce: 0.20).delay(delay)
    }

    private var modeLine: String {
        if !result.configuration.eventTitle.isEmpty {
            return result.configuration.eventTitle
        }
        if result.configuration.isSuddenDeath {
            return "Sudden Death • \(result.configuration.mode.title)"
        }
        return result.configuration.mode.title
    }

    private var nextTournamentConfiguration: MatchConfiguration? {
        guard result.configuration.mode == .tournament,
              result.playerWon,
              !result.configuration.isFinalTournamentRound else { return nil }
        return TournamentEvent.current().configuration(
            round: result.configuration.eventRound + 1,
            playerName: result.configuration.playerName,
            aimAssistance: result.configuration.aimAssistance
        )
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
