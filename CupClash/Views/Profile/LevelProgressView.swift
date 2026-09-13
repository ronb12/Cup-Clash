import SwiftUI

struct LevelProgressView: View {
    let totalXP: Int

    var body: some View {
        let progress = ProgressionMath.progress(totalXP: totalXP)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Level \(progress.level)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Spacer()
                Text("\(progress.intoLevel)/\(progress.needed) XP")
                    .foregroundStyle(CupClashTheme.textSecondary)
                    .monospacedDigit()
            }
            ProgressView(value: progress.fraction)
                .tint(CupClashTheme.cyan)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(progress.level), \(progress.intoLevel) of \(progress.needed) experience")
    }
}
