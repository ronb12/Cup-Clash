import RealityKit
import SwiftUI
import UIKit

/// Hosts the match ARView so a rematch can swap in a new scene without
/// SwiftUI reusing the previous match's view.
final class RealityHostView: UIView {
    func attach(_ arView: ARView) {
        if arView.superview === self { return }
        subviews.forEach { $0.removeFromSuperview() }
        arView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(arView)
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: topAnchor),
            arView.bottomAnchor.constraint(equalTo: bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

struct RealityGameContainer: UIViewRepresentable {
    let controller: GameSceneController

    func makeUIView(context: Context) -> RealityHostView {
        let host = RealityHostView()
        host.backgroundColor = UIColor(red: 0.03, green: 0.04, blue: 0.12, alpha: 1)
        host.attach(controller.ensureView())
        return host
    }

    func updateUIView(_ host: RealityHostView, context: Context) {
        host.attach(controller.ensureView())
    }
}
