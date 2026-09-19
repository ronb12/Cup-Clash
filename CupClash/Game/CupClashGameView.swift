import SwiftUI

struct CupClashGameView: View {
    @Bindable var coordinator: GameCoordinator
    /// Keeps the 3D viewport clear of an overlaid control panel.
    var bottomInset: CGFloat = 0

    var body: some View {
        RealityGameContainer(controller: coordinator.scene)
            .padding(.bottom, bottomInset)
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .onAppear {
                coordinator.start()
            }
    }
}
