import SwiftUI

struct ModeCardView: View {
    let title: String
    let detail: String
    let symbol: String
    var emphasized = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            AudioManager.shared.play(.button)
            HapticManager.shared.button()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(emphasized ? CupClashTheme.navy : CupClashTheme.cyan)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(emphasized ? Color.white.opacity(0.85) : CupClashTheme.cyan.opacity(0.15))
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                    Text(detail)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(emphasized ? CupClashTheme.navy.opacity(0.8) : CupClashTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(emphasized ? CupClashTheme.navy : CupClashTheme.textMuted)
            }
            .foregroundStyle(emphasized ? CupClashTheme.navy : CupClashTheme.textPrimary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: CupClashTheme.radiusL, style: .continuous)
                    .fill(emphasized ? AnyShapeStyle(CupClashTheme.neonGradient()) : AnyShapeStyle(CupClashTheme.navyPanel.opacity(0.88)))
            )
        }
        .frame(minHeight: CupClashTheme.minTouch)
        .accessibilityLabel(title)
        .accessibilityHint(detail)
    }
}
