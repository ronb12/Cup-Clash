import SwiftUI

struct ShotResultView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(CupClashTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.5)))
            .accessibilityLabel(text)
    }
}
