import SwiftUI

struct FormationPicker: View {
    @Binding var formation: CupFormation
    var cupCount: CupCount

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Formation", subtitle: "How the cups are racked")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(CupFormation.allCases) { item in
                    Button {
                        formation = item
                        AudioManager.shared.play(.button)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: item.symbolName)
                            Text(item.title)
                                .font(.system(.caption, design: .rounded).weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(formation == item ? CupClashTheme.navy : CupClashTheme.textPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(formation == item ? AnyShapeStyle(CupClashTheme.neonGradient()) : AnyShapeStyle(Color.white.opacity(0.06)))
                        )
                    }
                    .accessibilityLabel(item.title)
                    .accessibilityAddTraits(formation == item ? .isSelected : [])
                }
            }
            FormationPreview(formation: formation, cupCount: cupCount)
        }
    }
}

struct FormationPreview: View {
    let formation: CupFormation
    let cupCount: CupCount

    var body: some View {
        let points = FormationLayout.make(formation, count: cupCount, seed: 7).offsets
        GeometryReader { geo in
            let scale = min(geo.size.width, geo.size.height) * 0.38
            ZStack {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(CupClashTheme.cyan)
                        .frame(width: 16, height: 16)
                        .position(
                            x: geo.size.width / 2 + CGFloat(point.x) * CGFloat(scale) * 8,
                            y: geo.size.height / 2 + CGFloat(point.y) * CGFloat(scale) * 8
                        )
                }
            }
        }
        .frame(height: 96)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.28)))
        .accessibilityLabel("Preview of \(formation.title) with \(cupCount.rawValue) cups")
    }
}
