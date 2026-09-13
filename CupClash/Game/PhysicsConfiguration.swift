import Foundation
import simd

struct PhysicsConfiguration: Equatable, Sendable {
    var ballMass: Float = 0.012
    var restitution: Float = 0.64
    var friction: Float = 0.32
    var linearDamping: Float = 0.18
    var angularDamping: Float = 0.42
    var minimumThrowForce: Float = 0.18
    var maximumThrowForce: Float = 1.0
    var upwardArcMultiplier: Float = 2.55
    var sideAimMultiplier: Float = 0.42
    var gravity: SIMD3<Float> = ArenaMetrics.gravity
    var outOfBoundsX: Float = 1.35
    var outOfBoundsZ: Float = 1.85
    var outOfBoundsY: Float = -0.35
    var shotTimeout: TimeInterval = 4.2
    var settleSpeed: Float = 0.09
    var settleDuration: TimeInterval = 0.42
    var scoreHoldDuration: TimeInterval = 0.16
    var minLaunchPower: Float = 0.12

    static let playable = PhysicsConfiguration()
}
