import SwiftUI

struct StatisticsView: View {
    let profile: PlayerProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Statistics")
            row("Matches played", "\(profile.matchesPlayed)")
            row("Wins", "\(profile.matchesWon)")
            row("Losses", "\(profile.matchesLost)")
            row("Shots attempted", "\(profile.shotsAttempted)")
            row("Shots made", "\(profile.shotsMade)")
            row("Accuracy", AccuracyMath.formatted(made: profile.shotsMade, attempted: profile.shotsAttempted))
            row("Current streak", "\(profile.currentWinningStreak)")
            row("Best streak", "\(profile.bestWinningStreak)")
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(CupClashTheme.textSecondary)
            Spacer()
            Text(value).fontWeight(.bold)
        }
        .font(.system(.body, design: .rounded))
    }
}
