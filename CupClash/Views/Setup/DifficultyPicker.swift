import SwiftUI

struct DifficultyPicker: View {
    @Binding var difficulty: AIDifficulty

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Opponent", subtitle: "Computer skill")
            HStack(spacing: 8) {
                ForEach(AIDifficulty.allCases) { level in
                    chip(level)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func chip(_ level: AIDifficulty) -> some View {
        Button {
            difficulty = level
            AudioManager.shared.play(.button)
        } label: {
            Text(level.title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(difficulty == level ? CupClashTheme.navy : CupClashTheme.textPrimary)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(difficulty == level ? AnyShapeStyle(CupClashTheme.neonGradient()) : AnyShapeStyle(Color.white.opacity(0.06)))
                )
        }
        .accessibilityLabel(level.title)
        .accessibilityAddTraits(difficulty == level ? .isSelected : [])
        .accessibilityHint(level.detail)
    }
}
