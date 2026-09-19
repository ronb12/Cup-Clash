import SwiftUI

struct TournamentHubView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings
    var body: some View {
        let event = TournamentEvent.current()
        let store = TournamentStore.shared
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 16) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.title)
                                .font(CupClashTheme.headlineFont)
                            Text("Week \(event.weekID) • Win three matches in a row")
                                .foregroundStyle(CupClashTheme.textSecondary)
                            HStack {
                                Text("Titles")
                                Spacer()
                                Text("\(store.titles)")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundStyle(CupClashTheme.gold)
                                    .monospacedDigit()
                            }
                        }
                    }

                    ForEach(event.rounds) { round in
                        let status = store.status(for: round.index)
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(round.title)
                                        .font(.system(.headline, design: .rounded).weight(.bold))
                                    Spacer()
                                    Text(statusLabel(status))
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(statusColor(status))
                                }
                                Text("vs \(round.opponentName) • \(round.difficulty.title)")
                                    .foregroundStyle(CupClashTheme.textSecondary)
                                Text("\(round.cupCount.title) • \(round.formation.title)\(round.suddenDeathMakes > 0 ? " • Sudden Death" : "")\(round.movingTargets ? " • Moving cups" : "")")
                                    .font(.footnote)
                                    .foregroundStyle(CupClashTheme.textMuted)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(round.title), versus \(round.opponentName), \(statusLabel(status))")
                    }

                    if store.championThisWeek {
                        Text("You are this week's champion. Retry the bracket for practice and coins.")
                            .foregroundStyle(CupClashTheme.gold)
                            .font(.footnote.weight(.semibold))
                    } else if store.eliminated {
                        Text("Eliminated this run. Retry from the opening match.")
                            .foregroundStyle(CupClashTheme.warning)
                            .font(.footnote.weight(.semibold))
                    }

                    if let config = store.playableConfiguration(
                        playerName: profile.displayName,
                        aimAssistance: settings.aimAssistanceEnabled
                    ) {
                        PrimaryButton(title: playTitle(store), symbol: "play.fill", gold: store.currentRound >= 3) {
                            router.start(config)
                        }
                    } else if store.eliminated || store.isComplete {
                        PrimaryButton(title: store.isComplete ? "Play Again" : "Retry Bracket", symbol: "arrow.clockwise") {
                            store.retryWeek()
                            if let config = store.playableConfiguration(
                                playerName: profile.displayName,
                                aimAssistance: settings.aimAssistanceEnabled
                            ) {
                                router.start(config)
                            }
                        }
                    }

                    GameCenterSocialPanel(
                        boardID: GameCenterIDs.weeklyTournament,
                        detail: "The weekly cup is the same for everyone. Friend ranks use this week's tournament score."
                    )
                }
                .padding(20)
            }
        }
        .navigationTitle("Tournaments")
        .onAppear { store.refreshWeek() }
    }

    private func playTitle(_ store: TournamentStore) -> String {
        switch store.currentRound {
        case 2: "Play Semifinal"
        case 3: "Play Final"
        default: "Play Opening Match"
        }
    }

    private func statusLabel(_ status: TournamentRoundStatus) -> String {
        switch status {
        case .locked: "Locked"
        case .current: "Now"
        case .won: "Won"
        case .lost: "Lost"
        }
    }

    private func statusColor(_ status: TournamentRoundStatus) -> Color {
        switch status {
        case .locked: CupClashTheme.textMuted
        case .current: CupClashTheme.cyan
        case .won: CupClashTheme.gold
        case .lost: CupClashTheme.warning
        }
    }
}
