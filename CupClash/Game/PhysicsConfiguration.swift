import Foundation
import simd

struct PhysicsConfiguration: Equatable, Sendable {
    var ballMass: Float = 0.012
    var restitution: Float = 0.16
    var friction: Float = 0.38
    var linearDamping: Float = 0.0
    var angularDamping: Float = 0.36
    var minimumThrowForce: Float = 0.18
    var maximumThrowForce: Float = 1.0
    var upwardArcMultiplier: Float = 2.55
    var sideAimMultiplier: Float = 0.16
    var gravity: SIMD3<Float> = ArenaMetrics.gravity
    var outOfBoundsX: Float = 1.35
    var outOfBoundsZ: Float = 1.85
    var outOfBoundsY: Float = -0.35
    var shotTimeout: TimeInterval = 4.2
    var settleSpeed: Float = 0.09
    var settleDuration: TimeInterval = 0.42
    var scoreHoldDuration: TimeInterval = 0.04
    var scoreGraceDuration: TimeInterval = 0.22
    var inCupSpeed: Float = 0.62
    var minLaunchPower: Float = 0.12
    /// The simulated ball lands ~3% short of the ideal ballistic arc the guide draws,
    /// so horizontal launch speed is scaled up to make real shots match the guide.
    var launchCompensation: Float = 1.03

    static let playable = PhysicsConfiguration()
}
