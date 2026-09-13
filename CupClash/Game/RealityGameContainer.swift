import RealityKit
import SwiftUI

struct RealityGameContainer: UIViewRepresentable {
    let controller: GameSceneController

    func makeUIView(context: Context) -> ARView {
        controller.ensureView()
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
