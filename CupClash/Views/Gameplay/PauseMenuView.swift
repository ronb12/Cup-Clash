import SwiftUI

struct PauseMenuView: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onSettings: () -> Void
    let onHelp: () -> Void
    let onHome: () -> Void
    var confirmAbandon: Bool
    let onConfirmHome: () -> Void
    let onCancelHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            if confirmAbandon {
                GlassPanel {
                    VStack(spacing: 14) {
                        Text("Leave this match?")
                            .font(CupClashTheme.headlineFont)
                        Text("Progress for this game will be lost.")
                            .foregroundStyle(CupClashTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        PrimaryButton(title: "Keep Playing", action: onCancelHome)
                        SecondaryButton(title: "Leave Match", destructive: true, action: onConfirmHome)
                    }
                }
                .padding(28)
            } else {
                GlassPanel {
                    VStack(spacing: 12) {
                        Text("Paused")
                            .font(CupClashTheme.headlineFont)
                            .frame(maxWidth: .infinity)
                        PrimaryButton(title: "Resume", symbol: "play.fill", action: onResume)
                        SecondaryButton(title: "Restart Match", symbol: "arrow.clockwise", action: onRestart)
                        SecondaryButton(title: "Settings", symbol: "gearshape", action: onSettings)
                        SecondaryButton(title: "How to Play", symbol: "questionmark.circle", action: onHelp)
                        SecondaryButton(title: "Return Home", symbol: "house", destructive: true, action: onHome)
                    }
                }
                .padding(24)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}
