import SwiftUI

struct AimPowerControl: View {
    var enabled: Bool
    var leftHanded: Bool
    var aim: Float
    var power: Float
    var onChanged: (CGSize) -> Void
    var onEnded: () -> Void

    var body: some View {
        VStack(alignment: leftHanded ? .leading : .trailing, spacing: 8) {
            HStack {
                Text(aimLabel)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(CupClashTheme.textSecondary)
                Spacer()
                Text("Power \(Int(power * 100))")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(powerColor)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(powerGradient)
                        .frame(width: max(12, geo.size.width * CGFloat(power)))
                }
            }
            .frame(height: 12)
            .accessibilityHidden(true)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(enabled ? 0.10 : 0.04))
                .overlay(
                    VStack(spacing: 6) {
                        Image(systemName: "hand.draw.fill")
                        Text(enabled ? "Pull back to throw" : "Wait")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(CupClashTheme.textPrimary)
                )
                .frame(height: 96)
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            guard enabled else { return }
                            onChanged(value.translation)
                        }
                        .onEnded { _ in
                            guard enabled else { return }
                            onEnded()
                        }
                )
                .overlay {
                    if !enabled {
                        Color.black.opacity(0.15)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Throw control")
        .accessibilityHint("Drag left or right to aim, pull back toward you to add power, then release.")
        .accessibilityValue("Aim \(aimLabel), power \(Int(power * 100)) percent")
        .accessibilityAdjustableAction { direction in
            guard enabled else { return }
            let delta: CGFloat = direction == .increment ? 24 : -24
            onChanged(CGSize(width: 0, height: abs(delta) + 140))
            onEnded()
        }
    }

    private var aimLabel: String {
        if abs(aim) < 0.08 { return "Center" }
        return aim < 0 ? "Left" : "Right"
    }

    private var powerColor: Color {
        if power > 0.75 { return CupClashTheme.warning }
        if power > 0.4 { return CupClashTheme.cyan }
        return CupClashTheme.textSecondary
    }

    private var powerGradient: LinearGradient {
        LinearGradient(colors: [CupClashTheme.cyan, CupClashTheme.violet], startPoint: .leading, endPoint: .trailing)
    }
}
