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
                            labeled("1", "Touch the throw pad.")
                            labeled("2", "Drag left or right to aim.")
                            labeled("3", "Drag backward to add power.")
                            labeled("4", "Release to throw. The ball uses real physics.")
                        }
                    }
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Rules")
                            labeled("Turns", "One throw each, then the other side goes.")
                            labeled("Scoring", "The ball must settle inside a cup. Rim taps do not count.")
                            labeled("Re-rack", "Once per side when three or fewer of your cups remain.")
                            labeled("Practice", "Unlimited throws. No coins are awarded.")
                            labeled("Pass & Play", "The screen hides between turns until Ready is tapped.")
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
