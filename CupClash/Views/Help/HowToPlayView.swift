import SwiftUI

struct HowToPlayView: View {
    @Environment(GameSettings.self) private var settings

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Goal")
                            Text("Throw the ball into the other side’s cups. A made cup is removed. First to clear every opposing cup wins.")
                        }
                    }
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Throwing")
                            labeled("1", "Drag on the table to aim at a cup. Center is the front cups. Full side aim goes wide.")
                            labeled("2", "Drag backward for power. Too little falls short; more power reaches the back row.")
                            labeled("3", "Tap Throw to shoot along the dotted line.")
                        }
                    }
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Rules")
                            labeled("Turns", "One throw each. The camera swings around the table to the next player's view.")
                            labeled("Scoring", "The ball must settle inside a cup. Rim taps do not count.")
                            labeled("Re-rack", "Once per side when three or fewer of your cups remain.")
                            labeled("Daily Challenge", "A new seeded match every day. Wins add extra coins and a daily leaderboard score.")
                            labeled("Tournaments", "A weekly three-round cup. Win Opening, Semifinal, and Final to take the title.")
                            labeled("Challenges", "Special matches and objectives. Complete them for coins and the Challenges board.")
                            labeled("Sudden Death", "Optional Quick Match rule. First player to make 3 cups wins.")
                            labeled("Practice", "Unlimited throws. No coins are awarded.")
                            labeled("Pass & Play", "The screen hides between turns until Ready is tapped. Then the camera swings to that player's end.")
                            labeled("Leaderboards", "Career boards are saved on device. Sign in to Game Center to compete with friends.")
                            labeled("Friends", "Invite Game Center friends from Settings, Tournaments, Challenges, or Leaderboards. The weekly cup and challenge clears sync so friends can compare ranks. Matches themselves are still played on your device.")
                        }
                    }
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Family-friendly")
                            Text("Cups hold water, soda, or colorful fictional drinks. There is no alcohol, gambling, or intoxication.")
                        }
                    }
                    CreatorCredit()
                }
                .padding(20)
            }
        }
        .navigationTitle("How to Play")
    }

    private func labeled(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(.headline, design: .rounded).weight(.bold))
            Text(detail).foregroundStyle(CupClashTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}
