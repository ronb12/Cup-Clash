import Foundation
import RealityKit
import simd

struct CameraPose: Equatable, Sendable {
    var position: SIMD3<Float>
    var lookAt: SIMD3<Float>
}

@MainActor
final class GameCameraController {
    private(set) var current: CameraPose
    private var target: CameraPose
    var reducedMotion = false
    var followBall = true

    init() {
        let pose = Self.aimingPose(for: .player)
        current = pose
        target = pose
    }

    func aiming(for side: PlayerSide) {
        target = Self.aimingPose(for: side)
        if reducedMotion {
            current = target
        }
    }

    func follow(ballPosition: SIMD3<Float>, side: PlayerSide) {
        guard followBall else { return }
        let base = Self.aimingPose(for: side)
        let mix: Float = reducedMotion ? 0.08 : 0.16
        target = CameraPose(
            position: simd_mix(base.position, ballPosition + SIMD3(0, 0.95, side == .player ? 1.05 : -1.05), SIMD3(repeating: mix)),
            lookAt: simd_mix(base.lookAt, ballPosition, SIMD3(repeating: 0.22))
        )
    }

    func tick(delta: Float) {
        let rate: Float = reducedMotion ? 1.0 : min(1, delta * 4.2)
        current.position = simd_mix(current.position, target.position, SIMD3(repeating: rate))
        current.lookAt = simd_mix(current.lookAt, target.lookAt, SIMD3(repeating: rate))
    }

    func apply(to camera: Entity) {
        camera.look(at: current.lookAt, from: current.position, relativeTo: nil)
    }

    static func aimingPose(for side: PlayerSide) -> CameraPose {
        if side == .player {
            return CameraPose(position: SIMD3(0, 1.70, 2.12), lookAt: SIMD3(0, 0.80, -0.62))
        }
        return CameraPose(position: SIMD3(0, 1.70, -2.12), lookAt: SIMD3(0, 0.80, 0.62))
    }
}
