import SwiftUI

struct CoinBadge: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill")
                .foregroundStyle(CupClashTheme.gold)
                .accessibilityHidden(true)
            Text("\(amount)")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(CupClashTheme.gold)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.black.opacity(0.35)))
        .accessibilityLabel("\(amount) coins")
    }
}
