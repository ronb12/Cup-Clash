import SwiftUI

struct GlassPanel<Content: View>: View {
    var padded = true
    @ViewBuilder var content: () -> Content
    @Environment(GameSettings.self) private var settings

    var body: some View {
        content()
            .padding(padded ? CupClashTheme.spacingM : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CupClashTheme.radiusL, style: .continuous)
                    .fill(settings.highContrast ? Color.black.opacity(0.82) : CupClashTheme.navyPanel.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: CupClashTheme.radiusL, style: .continuous)
                            .stroke(CupClashTheme.cyan.opacity(settings.highContrast ? 0.7 : 0.22), lineWidth: 1)
                    )
            )
            .cupClashCardShadow()
    }
}
