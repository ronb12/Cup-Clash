import SwiftUI

struct CupCountPicker: View {
    @Binding var cupCount: CupCount

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Cups", subtitle: "Six or ten per side")
            HStack(spacing: 8) {
                ForEach(CupCount.allCases) { count in
                    Button {
                        cupCount = count
                        AudioManager.shared.play(.button)
                    } label: {
                        Text(count.title)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(cupCount == count ? CupClashTheme.navy : CupClashTheme.textPrimary)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(cupCount == count ? AnyShapeStyle(CupClashTheme.goldGradient()) : AnyShapeStyle(Color.white.opacity(0.06)))
                            )
                    }
                    .accessibilityLabel(count.title)
                    .accessibilityAddTraits(cupCount == count ? .isSelected : [])
                }
            }
        }
    }
}
