import SwiftUI

struct MatchSetupView: View {
    let mode: GameMode
    @Environment(AppRouter.self) private var router
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings
    @State private var difficulty: AIDifficulty = .rookie
    @State private var cupCount: CupCount = .six
    @State private var formation: CupFormation = .triangle
    @State private var aimAssist = true
    @State private var suddenDeath = false

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 18) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(mode.title)
                                .font(CupClashTheme.headlineFont)
                            Text(mode.detail)
                                .foregroundStyle(CupClashTheme.textSecondary)
                        }
                    }

                    if mode == .quickMatch {
                        GlassPanel {
                            DifficultyPicker(difficulty: $difficulty)
                        }
                    }

                    GlassPanel {
                        CupCountPicker(cupCount: $cupCount)
                    }

                    GlassPanel {
                        FormationPicker(formation: $formation, cupCount: cupCount)
                    }

                    if mode.usesAI {
                        GlassPanel {
                            Toggle("Sudden Death (first to 3 cups)", isOn: $suddenDeath)
                                .tint(CupClashTheme.violet)
                                .font(.system(.headline, design: .rounded))
                        }
                    }

                    GlassPanel {
                        Toggle("Aim assistance", isOn: $aimAssist)
                            .tint(CupClashTheme.cyan)
                            .font(.system(.headline, design: .rounded))
                    }

                    PrimaryButton(title: "Start Match", symbol: "play.fill") {
                        router.start(makeConfiguration())
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            difficulty = settings.preferredDifficulty
            cupCount = settings.preferredCupCount
            aimAssist = settings.aimAssistanceEnabled
        }
    }

    private func makeConfiguration() -> MatchConfiguration {
        MatchConfiguration(
            mode: mode,
            difficulty: difficulty,
            cupCount: cupCount,
            formation: formation,
            aimAssistance: aimAssist,
            playerName: mode == .passAndPlay ? "Player One" : profile.displayName,
            opponentName: mode == .passAndPlay ? "Player Two" : difficulty.title,
            movingTargets: false,
            seed: UInt64.random(in: 1...UInt64.max),
            suddenDeathMakes: suddenDeath && mode.usesAI ? 3 : 0
        )
    }
}
