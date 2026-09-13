import SwiftUI

struct SecondaryButton: View {
    let title: String
    var symbol: String? = nil
    var destructive = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            AudioManager.shared.play(.button)
            HapticManager.shared.button()
            action()
        }) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .foregroundStyle(destructive ? CupClashTheme.warning : CupClashTheme.cyan)
            .background(
                RoundedRectangle(cornerRadius: CupClashTheme.radiusM, style: .continuous)
                    .stroke(destructive ? CupClashTheme.warning : CupClashTheme.cyan.opacity(0.7), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: CupClashTheme.radiusM, style: .continuous)
                            .fill(CupClashTheme.navyPanel.opacity(0.86))
                    )
            )
        }
        .accessibilityLabel(title)
    }
}
