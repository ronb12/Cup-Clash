import SwiftUI

struct TurnBannerView: View {
    let name: String
    let sideLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("\(name) • \(sideLabel)")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
        }
        .foregroundStyle(CupClashTheme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.black.opacity(0.45)))
        .accessibilityLabel("Current turn, \(name)")
    }
}
