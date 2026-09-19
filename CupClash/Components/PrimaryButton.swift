import SwiftUI

struct PrimaryButton: View {
    let title: String
    var symbol: String? = nil
    var gold = false
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: {
            AudioManager.shared.play(.button)
            HapticManager.shared.button()
            action()
        }) {
            HStack(spacing: 10) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: CupClashTheme.buttonHeight)
            .foregroundStyle(enabled ? (gold ? CupClashTheme.navy : .white) : CupClashTheme.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: CupClashTheme.radiusM, style: .continuous)
                    .fill(enabled
                          ? (gold ? AnyShapeStyle(CupClashTheme.goldGradient()) : AnyShapeStyle(CupClashTheme.neonGradient()))
                          : AnyShapeStyle(Color.white.opacity(0.10)))
            )
        }
        .disabled(!enabled)
        .accessibilityLabel(title)
    }
}
