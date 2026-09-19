import SwiftUI

struct PracticeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings
    @State private var cupCount: CupCount = .six
    @State private var formation: CupFormation = .triangle
    @State private var movingTargets = false
    @State private var coordinator: GameCoordinator?

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            if let coordinator {
                CupClashGameView(coordinator: coordinator, bottomInset: 150)
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button {
                            coordinator.teardown()
                            router.popToHome()
                        } label: {
                            Image(systemName: "xmark")
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.black.opacity(0.45)))
                        }
                        .accessibilityLabel("Close practice")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Made \(coordinator.state.playerMakes)/\(coordinator.state.playerShots)")
                            Text(AccuracyMath.formatted(made: coordinator.state.playerMakes, attempted: coordinator.state.playerShots))
                                .foregroundStyle(CupClashTheme.cyan)
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)

                    HStack(spacing: 8) {
                        compactReset("Reset Ball", action: coordinator.resetPracticeBall)
                        compactReset("Reset Cups", action: coordinator.resetPracticeCups)
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    ShotResultView(text: coordinator.feedback)

                    TableAimSurface(
                        enabled: coordinator.canThrow,
                        onChanged: coordinator.updateAim,
                        onEnded: coordinator.lockAim
                    )

                    AimPowerControl(
                        enabled: coordinator.canThrow,
                        leftHanded: settings.leftHandedControls,
                        aim: coordinator.throwInput.aim,
                        power: coordinator.throwInput.power,
                        onShoot: { coordinator.throwStraight() },
                        onNudgeAim: coordinator.nudgeAim
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        GlassPanel {
                            CupCountPicker(cupCount: $cupCount)
                        }
                        GlassPanel {
                            FormationPicker(formation: $formation, cupCount: cupCount)
                        }
                        GlassPanel {
                            Toggle("Moving target challenge", isOn: $movingTargets)
                                .tint(CupClashTheme.cyan)
                                .font(.system(.headline, design: .rounded))
                        }
                        PrimaryButton(title: "Start Practice", symbol: "target") {
                            coordinator = GameCoordinator(
                                configuration: MatchConfiguration(
                                    mode: .practice,
                                    difficulty: .rookie,
                                    cupCount: cupCount,
                                    formation: formation,
                                    aimAssistance: settings.aimAssistanceEnabled,
                                    playerName: profile.displayName,
                                    opponentName: "Targets",
                                    movingTargets: movingTargets,
                                    seed: UInt64.random(in: 1...UInt64.max)
                                ),
                                settings: settings,
                                profile: profile
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle(coordinator == nil ? "Practice" : "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(coordinator != nil)
        .onDisappear {
            coordinator?.teardown()
        }
    }

    private func compactReset(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(.caption, design: .rounded).weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(CupClashTheme.cyan)
            .background(Capsule().stroke(CupClashTheme.cyan.opacity(0.7), lineWidth: 1.2))
            .accessibilityLabel(title)
    }
}
