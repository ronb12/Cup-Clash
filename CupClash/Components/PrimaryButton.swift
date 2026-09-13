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
            .foregroundStyle(gold ? CupClashTheme.navy : .white)
            .background(
                RoundedRectangle(cornerRadius: CupClashTheme.radiusM, style: .continuous)
                    .fill(gold ? CupClashTheme.goldGradient() : CupClashTheme.neonGradient())
            )
            .opacity(enabled ? 1 : 0.45)
        }
        .disabled(!enabled)
        .accessibilityLabel(title)
    }
}
