import SwiftUI

struct TableAimSurface: View {
    var enabled: Bool
    var onChanged: (CGSize) -> Void
    var onEnded: () -> Void

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard enabled else { return }
                        onChanged(value.translation)
                    }
                    .onEnded { _ in
                        onEnded()
                    }
            )
            .accessibilityHidden(true)
    }
}

struct AimPowerControl: View {
    var enabled: Bool
    var leftHanded: Bool
    var aim: Float
    var power: Float
    var onShoot: () -> Void
    var onNudgeAim: ((Float) -> Void)? = nil

    var body: some View {
        VStack(alignment: leftHanded ? .leading : .trailing, spacing: 8) {
            HStack {
                Text(aimLabel)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(CupClashTheme.textSecondary)
                    .accessibilityLabel("Aim \(aimLabel)")
                    .accessibilityAdjustableAction { direction in
                        guard let onNudgeAim, enabled else { return }
                        switch direction {
                        case .increment: onNudgeAim(0.28)
                        case .decrement: onNudgeAim(-0.28)
                        @unknown default: break
                        }
                    }
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
                        .frame(width: max(12, geo.size.width * CGFloat(max(power, 0.04))))
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)

            HStack(spacing: 10) {
                Text(power > 0 ? "Drag sideways to aim" : "Drag down to set power")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(CupClashTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Throw", action: onShoot)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .frame(minWidth: 120, minHeight: 44)
                    .foregroundStyle(canShoot ? CupClashTheme.navy : CupClashTheme.textMuted)
                    .background(
                        Capsule().fill(canShoot ? AnyShapeStyle(CupClashTheme.neonGradient()) : AnyShapeStyle(Color.white.opacity(0.12)))
                    )
                    .disabled(!canShoot)
                    .accessibilityLabel("Throw")
                    .accessibilityHint(power > 0 ? "Throws using the current aim and power" : "Set power first by dragging down on the table")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var canShoot: Bool { enabled && power > 0 }

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
