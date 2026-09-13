import SwiftUI

struct CupClashGameView: View {
    @Bindable var coordinator: GameCoordinator

    var body: some View {
        RealityGameContainer(controller: coordinator.scene)
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .onAppear {
                coordinator.start()
            }
    }
}
