import SwiftUI

struct RewardSummaryView: View {
    let result: MatchResult
    var animateNumbers = false
    @State private var shownMatchXP = 0.0
    @State private var shownWinXP = 0.0
    @State private var shownCupXP = 0.0
    @State private var shownStreakXP = 0.0
    @State private var shownCoins = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Rewards")
            rewardRow("Match XP", value: shownMatchXP)
            if result.rewards.winXP > 0 {
                rewardRow("Victory XP", value: shownWinXP)
            }
            rewardRow("Cups XP", value: shownCupXP)
            if result.rewards.streakXP > 0 {
                rewardRow("Streak bonus", value: shownStreakXP)
            }
            rewardRow("Coins", value: shownCoins, color: CupClashTheme.gold)
            if result.rewards.levelsGained > 0 {
                Text("Level up! +\(result.rewards.levelUpCoins) coins")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(CupClashTheme.gold)
                    .scaleEffect(animateNumbers && shownCoins > 0 ? 1 : 0.92)
            }
            LevelProgressView(totalXP: result.endingTotalXP)
        }
        .onAppear { snapOrCount() }
        .onChange(of: animateNumbers) { _, _ in snapOrCount() }
    }

    private func snapOrCount() {
        if !animateNumbers {
            shownMatchXP = Double(result.rewards.matchXP)
            shownWinXP = Double(result.rewards.winXP)
            shownCupXP = Double(result.rewards.cupXP)
            shownStreakXP = Double(result.rewards.streakXP)
            shownCoins = Double(result.rewards.totalCoins)
            return
        }
        shownMatchXP = 0
        shownWinXP = 0
        shownCupXP = 0
        shownStreakXP = 0
        shownCoins = 0
        withAnimation(.easeOut(duration: 0.85)) {
            shownMatchXP = Double(result.rewards.matchXP)
            shownWinXP = Double(result.rewards.winXP)
            shownCupXP = Double(result.rewards.cupXP)
            shownStreakXP = Double(result.rewards.streakXP)
            shownCoins = Double(result.rewards.totalCoins)
        }
    }

    private func rewardRow(_ title: String, value: Double, color: Color = CupClashTheme.cyan) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(CupClashTheme.textSecondary)
            Spacer()
            CountingNumberText(value: value, color: color)
        }
        .font(.system(.body, design: .rounded))
    }
}
