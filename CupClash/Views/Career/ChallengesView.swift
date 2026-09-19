import SwiftUI

struct ChallengesView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings
    var body: some View {
        let featured = Set(ChallengeDefinition.featuredIDs())
        let completed = ChallengeStore.shared.completedCount
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 16) {
                    GlassPanel {
                        HStack {
                            Text("Progress")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                            Spacer()
                            Text("\(completed)/\(ChallengeDefinition.all.count)")
                                .foregroundStyle(CupClashTheme.cyan)
                                .monospacedDigit()
                        }
                    }

                    GameCenterSocialPanel(
                        boardID: GameCenterIDs.challengesCleared,
                        detail: "Challenge clears sync online so friends can see who finished more objectives."
                    )

                    SectionHeader(title: "This Week")
                    ForEach(ChallengeDefinition.all.filter { featured.contains($0.id) }) { challenge in
                        challengeCard(challenge, badge: "Featured")
                    }

                    SectionHeader(title: "All Challenges")
                    ForEach(ChallengeDefinition.all) { challenge in
                        challengeCard(challenge, badge: nil)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Challenges")
    }

    private func challengeCard(_ challenge: ChallengeDefinition, badge: String?) -> some View {
        let done = ChallengeStore.shared.isComplete(challenge.id)
        return GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: challenge.symbolName)
                        .font(.title2)
                        .foregroundStyle(done ? CupClashTheme.gold : CupClashTheme.cyan)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(challenge.title)
                                .font(.system(.headline, design: .rounded).weight(.bold))
                            if let badge {
                                Text(badge)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(CupClashTheme.violet.opacity(0.8)))
                            }
                            Spacer()
                            Text(done ? "Done" : "+\(challenge.rewardCoins)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(done ? CupClashTheme.gold : CupClashTheme.cyan)
                        }
                        Text(challenge.detail)
                            .foregroundStyle(CupClashTheme.textSecondary)
                    }
                }
                PrimaryButton(
                    title: done ? "Play Again" : "Play",
                    symbol: "play.fill",
                    gold: done,
                    action: {
                        router.start(
                            challenge.configuration(
                                playerName: profile.displayName,
                                aimAssistance: settings.aimAssistanceEnabled
                            )
                        )
                    }
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(challenge.title), \(done ? "complete" : "\(challenge.rewardCoins) coins")")
    }
}
