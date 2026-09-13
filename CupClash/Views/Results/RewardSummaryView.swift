import SwiftUI

struct RewardSummaryView: View {
    let result: MatchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Rewards")
            rewardRow("Match XP", value: "+\(result.rewards.matchXP)")
            if result.rewards.winXP > 0 {
                rewardRow("Victory XP", value: "+\(result.rewards.winXP)")
            }
            rewardRow("Cups XP", value: "+\(result.rewards.cupXP)")
            if result.rewards.streakXP > 0 {
                rewardRow("Streak bonus", value: "+\(result.rewards.streakXP)")
            }
            rewardRow("Coins", value: "+\(result.rewards.totalCoins)")
            if result.rewards.levelsGained > 0 {
                Text("Level up! +\(result.rewards.levelUpCoins) coins")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(CupClashTheme.gold)
            }
            LevelProgressView(totalXP: result.endingTotalXP)
        }
    }

    private func rewardRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(CupClashTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(CupClashTheme.cyan)
                .fontWeight(.bold)
        }
        .font(.system(.body, design: .rounded))
    }
}
