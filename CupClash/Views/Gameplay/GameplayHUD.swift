import SwiftUI

struct GameplayHUD: View {
    @Bindable var coordinator: GameCoordinator
    let onPause: () -> Void
    let onRerack: () -> Void

    var body: some View {
        let state = coordinator.state
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                MatchScoreColumn(
                    name: coordinator.configuration.playerName,
                    makes: state.playerMakes,
                    shots: state.playerShots,
                    cupsLeft: state.rackRemaining(for: .player),
                    accent: CupClashTheme.cyan,
                    alignment: .leading,
                    isActive: state.activeSide == .player
                )
                Spacer()
                VStack(spacing: 2) {
                    Button(action: onPause) {
                        Image(systemName: "pause.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.45)))
                    }
                    .accessibilityLabel("Pause")
                    Text("\(state.playerMakes)–\(state.opponentMakes)")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .accessibilityLabel("Score \(state.playerMakes) to \(state.opponentMakes)")
                    if !coordinator.configuration.eventTitle.isEmpty {
                        Text(coordinator.configuration.eventTitle)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CupClashTheme.cyan)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .accessibilityLabel(coordinator.configuration.eventTitle)
                    }
                    if coordinator.configuration.isSuddenDeath {
                        Text("First to \(coordinator.configuration.suddenDeathMakes)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CupClashTheme.gold)
                            .accessibilityLabel("Sudden Death, first to \(coordinator.configuration.suddenDeathMakes)")
                    }
                }
                Spacer()
                MatchScoreColumn(
                    name: coordinator.configuration.opponentName,
                    makes: state.opponentMakes,
                    shots: state.opponentShots,
                    cupsLeft: state.rackRemaining(for: .opponent),
                    accent: CupClashTheme.violet,
                    alignment: .trailing,
                    isActive: state.activeSide == .opponent
                )
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.top, 6)

            TurnBannerView(
                name: coordinator.currentPlayerName,
                sideLabel: coordinator.configuration.mode.usesAI && state.activeSide == .opponent
                    ? "rival view"
                    : "your view"
            )
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
                if coordinator.state.canRerack(for: coordinator.configuration.mode == .passAndPlay ? coordinator.state.activeSide : .player) {
                    Button("Re-rack", action: onRerack)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(CupClashTheme.violet.opacity(0.85)))
                        .foregroundStyle(.white)
                        .padding(.trailing, 8)
                        .accessibilityHint("Rearrange remaining cups once")
                }
            }

            ShotResultView(text: coordinator.feedback)

            TableAimSurface(
                enabled: coordinator.canThrow,
                onChanged: coordinator.updateAim,
                onEnded: coordinator.lockAim
            )

            AimPowerControl(
                enabled: coordinator.canThrow,
                leftHanded: coordinator.settings.leftHandedControls,
                aim: coordinator.throwInput.aim,
                power: coordinator.throwInput.power,
                onShoot: { coordinator.throwStraight() },
                onNudgeAim: coordinator.nudgeAim
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

private struct MatchScoreColumn: View {
    let name: String
    let makes: Int
    let shots: Int
    let cupsLeft: Int
    let accent: Color
    let alignment: HorizontalAlignment
    let isActive: Bool

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(name)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(isActive ? accent : .white)
            Text("Made \(makes)/\(shots)")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(accent)
                .monospacedDigit()
            Text("\(cupsLeft) cups left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CupClashTheme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), made \(makes) of \(shots), \(cupsLeft) cups left")
    }
}
