import SwiftUI

struct PlayerHeaderView: View {
    let profile: PlayerProfile

    var body: some View {
        let progress = ProgressionMath.progress(totalXP: profile.totalXP)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(profile.displayName)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(CupClashTheme.textPrimary)
                Text("Level \(progress.level)")
                    .font(CupClashTheme.captionFont)
                    .foregroundStyle(CupClashTheme.cyan)
                ProgressView(value: progress.fraction)
                    .tint(CupClashTheme.cyan)
                    .accessibilityLabel("Experience progress")
                    .accessibilityValue("\(progress.intoLevel) of \(progress.needed)")
            }
            Spacer()
            CoinBadge(amount: profile.coinBalance)
        }
        .accessibilityElement(children: .contain)
    }
}
