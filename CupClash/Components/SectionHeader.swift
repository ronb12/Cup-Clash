import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(CupClashTheme.headlineFont)
                .foregroundStyle(CupClashTheme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(CupClashTheme.captionFont)
                    .foregroundStyle(CupClashTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct CreatorCredit: View {
    var compact = false

    var body: some View {
        VStack(spacing: compact ? 2 : 4) {
            Text(AppCredits.createdBy)
            Text(AppCredits.owner)
        }
        .font(compact ? .caption.weight(.semibold) : .footnote.weight(.semibold))
        .foregroundStyle(CupClashTheme.gold)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AppCredits.fullLine)
    }
}
