import SwiftUI

struct AchievementsView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 12) {
                    let completed = AchievementDefinition.all.filter {
                        AchievementProgress.isComplete(for: $0, profile: profile, scoreboard: .shared)
                    }.count
                    GlassPanel {
                        HStack {
                            Text("Progress")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                            Spacer()
                            Text("\(completed)/\(AchievementDefinition.all.count)")
                                .foregroundStyle(CupClashTheme.cyan)
                                .monospacedDigit()
                        }
                    }

                    ForEach(AchievementDefinition.all) { achievement in
                        let percent = AchievementProgress.percent(for: achievement, profile: profile, scoreboard: .shared)
                        GlassPanel {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: achievement.symbolName)
                                    .font(.title2)
                                    .foregroundStyle(percent >= 100 ? CupClashTheme.gold : CupClashTheme.cyan)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(achievement.title)
                                        .font(.system(.headline, design: .rounded).weight(.bold))
                                    Text(achievement.detail)
                                        .foregroundStyle(CupClashTheme.textSecondary)
                                    ProgressView(value: percent / 100)
                                        .tint(percent >= 100 ? CupClashTheme.gold : CupClashTheme.cyan)
                                    Text(percent >= 100 ? "Complete" : "\(Int(percent))%")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(percent >= 100 ? CupClashTheme.gold : CupClashTheme.textMuted)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(achievement.title), \(percent >= 100 ? "complete" : "\(Int(percent)) percent")")
                    }

                    if GameCenterManager.shared.isAuthenticated {
                        SecondaryButton(title: "Open Game Center Achievements", symbol: "gamecontroller") {
                            GameCenterManager.shared.presentAchievements()
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Achievements")
    }
}
