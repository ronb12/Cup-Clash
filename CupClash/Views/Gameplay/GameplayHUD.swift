import SwiftUI

struct GameplayHUD: View {
    let coordinator: GameCoordinator
    let onPause: () -> Void
    let onRerack: () -> Void

    var body: some View {
        let state = coordinator.state
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coordinator.configuration.playerName)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                    Text("Cups \(state.playerCupsRemaining)")
                        .foregroundStyle(CupClashTheme.cyan)
                    Text("Streak \(state.currentMakeStreak)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CupClashTheme.gold)
                }
                Spacer()
                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.black.opacity(0.45)))
                }
                .accessibilityLabel("Pause")
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(coordinator.configuration.opponentName)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                    Text("Cups \(state.opponentCupsRemaining)")
                        .foregroundStyle(CupClashTheme.violet)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.top, 6)

            TurnBannerView(
                name: coordinator.currentPlayerName,
                sideLabel: state.activeSide == .player ? "Near side" : "Far side"
            )

            ShotResultView(text: coordinator.feedback)
            Spacer()

            if coordinator.state.canRerack(for: coordinator.configuration.mode == .passAndPlay ? coordinator.state.activeSide : .player) {
                Button("Re-rack", action: onRerack)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(CupClashTheme.violet.opacity(0.85)))
                    .foregroundStyle(.white)
                    .accessibilityHint("Rearrange remaining cups once")
            }

            AimPowerControl(
                enabled: coordinator.canThrow,
                leftHanded: coordinator.settings.leftHandedControls,
                aim: coordinator.throwInput.aim,
                power: coordinator.throwInput.power,
                onChanged: coordinator.updateAim,
                onEnded: coordinator.releaseThrow
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .allowsHitTesting(true)
    }
}
