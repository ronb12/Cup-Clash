import SwiftUI

struct GameplayView: View {
    let configuration: MatchConfiguration
    @Environment(AppRouter.self) private var router
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings
    @State private var coordinator: GameCoordinator?
    @State private var showSettings = false
    @State private var showHelp = false

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            if let coordinator {
                CupClashGameView(coordinator: coordinator, bottomInset: 150)
                    .id(configuration.seed)
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(colors: [.clear, CupClashTheme.navy.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 36)
                }
                .padding(.bottom, 150)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                GameplayHUD(
                    coordinator: coordinator,
                    onPause: coordinator.togglePause,
                    onRerack: coordinator.requestRerack
                )

                if coordinator.phase == .passOverlay {
                    passOverlay(coordinator)
                }

                if coordinator.isPaused {
                    PauseMenuView(
                        onResume: coordinator.resume,
                        onRestart: coordinator.restart,
                        onSettings: { showSettings = true },
                        onHelp: { showHelp = true },
                        onHome: coordinator.requestAbandon,
                        confirmAbandon: coordinator.confirmAbandon,
                        onConfirmHome: {
                            coordinator.teardown()
                            router.popToHome()
                        },
                        onCancelHome: coordinator.resume
                    )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: configuration.seed) {
            bootMatch()
        }
        .onChange(of: coordinator?.phase) { _, phase in
            if phase == .finished, let result = coordinator?.result {
                router.showResults(result)
            }
        }
        .onDisappear {
            coordinator?.teardown()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHelp) {
            HowToPlayView()
        }
    }

    private func bootMatch() {
        if let current = coordinator, current.configuration.seed == configuration.seed {
            current.start()
            return
        }
        coordinator?.teardown()
        let fresh = GameCoordinator(configuration: configuration, settings: settings, profile: profile)
        coordinator = fresh
        fresh.start()
    }

    private func passOverlay(_ coordinator: GameCoordinator) -> some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "eye.slash.fill")
                    .font(.largeTitle)
                    .foregroundStyle(CupClashTheme.cyan)
                Text("Pass to \(coordinator.currentPlayerName)")
                    .font(CupClashTheme.headlineFont)
                    .multilineTextAlignment(.center)
                Text("Hide the table until they tap Ready.")
                    .foregroundStyle(CupClashTheme.textSecondary)
                PrimaryButton(title: "Ready", symbol: "hand.tap.fill") {
                    coordinator.acknowledgePass()
                }
            }
            .padding(28)
        }
        .accessibilityAddTraits(.isModal)
    }
}
