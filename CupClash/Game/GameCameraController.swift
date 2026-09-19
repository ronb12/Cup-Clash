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
    private var orbit: Orbit?
    var reducedMotion = false
    var followBall = true

    private struct Orbit {
        var start: CameraPose
        var end: CameraPose
        var elapsed: Float = 0
        var duration: Float
    }

    var isTraveling: Bool { orbit != nil }

    init() {
        let pose = Self.aimingPose(for: .player)
        current = pose
        target = pose
    }

    func aiming(for side: PlayerSide) {
        let destination = Self.aimingPose(for: side)
        target = destination
        if reducedMotion || Self.aligned(current, destination) {
            orbit = nil
            current = destination
            return
        }
        orbit = Orbit(start: current, end: destination, duration: 0.88)
    }

    func snap(to side: PlayerSide) {
        let pose = Self.aimingPose(for: side)
        orbit = nil
        current = pose
        target = pose
    }

    func follow(ballPosition: SIMD3<Float>, side: PlayerSide) {
        guard followBall, orbit == nil else { return }
        let base = Self.aimingPose(for: side)
        let mix: Float = reducedMotion ? 0.08 : 0.16
        let behind: Float = side == .player ? 1.05 : -1.05
        target = CameraPose(
            position: simd_mix(base.position, ballPosition + SIMD3(0, 0.95, behind), SIMD3(repeating: mix)),
            lookAt: simd_mix(base.lookAt, ballPosition, SIMD3(repeating: 0.22))
        )
    }

    func tick(delta: Float) {
        if var orbit {
            orbit.elapsed += delta
            let linear = min(1, orbit.elapsed / max(orbit.duration, 0.01))
            current = Self.orbitPose(from: orbit.start, to: orbit.end, t: Self.smoothstep(linear))
            if linear >= 1 {
                current = orbit.end
                target = orbit.end
                self.orbit = nil
            } else {
                self.orbit = orbit
            }
            return
        }
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

    static func orbitPose(from start: CameraPose, to end: CameraPose, t: Float) -> CameraPose {
        let clamped = t.clamped(to: 0...1)
        let startAngle = atan2(start.position.x, start.position.z)
        let endAngle = atan2(end.position.x, end.position.z)
        var sweep = endAngle - startAngle
        while sweep <= 0 { sweep += 2 * Float.pi }
        while sweep > 2 * Float.pi { sweep -= 2 * Float.pi }
        let angle = startAngle + sweep * clamped

        let startRadius = hypot(start.position.x, start.position.z)
        let endRadius = hypot(end.position.x, end.position.z)
        let radius = simd_mix(startRadius, endRadius, clamped) + sin(clamped * .pi) * 0.32
        let height = simd_mix(start.position.y, end.position.y, clamped) + sin(clamped * .pi) * 0.22

        let tableCenter = SIMD3<Float>(0, 0.84, 0)
        let lookBlend = Self.smoothstep((clamped - 0.55) / 0.45)
        return CameraPose(
            position: SIMD3(sin(angle) * radius, height, cos(angle) * radius),
            lookAt: simd_mix(tableCenter, end.lookAt, SIMD3(repeating: lookBlend))
        )
    }

    static func smoothstep(_ t: Float) -> Float {
        let x = t.clamped(to: 0...1)
        return x * x * (3 - 2 * x)
    }

    private static func aligned(_ a: CameraPose, _ b: CameraPose) -> Bool {
        simd_distance(a.position, b.position) < 0.08
    }
}
