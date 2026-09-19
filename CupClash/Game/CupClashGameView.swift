import SwiftUI

struct CupClashGameView: View {
    @Bindable var coordinator: GameCoordinator
    /// Keeps the 3D viewport clear of an overlaid control panel.
    var bottomInset: CGFloat = 0

    var body: some View {
        RealityGameContainer(controller: coordinator.scene)
            .overlay(alignment: .bottom) {
                if bottomInset > 0 {
                    LinearGradient(colors: [.clear, CupClashTheme.navy.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 36)
                        .allowsHitTesting(false)
                }
            }
            .padding(.bottom, bottomInset)
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .onAppear {
                coordinator.start()
            }
    }
}
