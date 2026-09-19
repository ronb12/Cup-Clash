import Foundation
import simd

enum TrajectoryCalculator {
    /// Smaller than half of `ArenaMetrics.cupSpacing` so assist cannot cover the whole rack.
    static let aimAssistSnapRadius: Float = 0.038

    static func initialVelocity(
        from origin: SIMD3<Float>,
        to target: SIMD3<Float>,
        flightTime: Float,
        gravity: SIMD3<Float> = ArenaMetrics.gravity
    ) -> SIMD3<Float> {
        let time = max(0.28, flightTime)
        let g = abs(gravity.y)
        return SIMD3(
            (target.x - origin.x) / time,
            (target.y - origin.y + 0.5 * g * time * time) / time,
            (target.z - origin.z) / time
        )
    }

    static func point(
        origin: SIMD3<Float>,
        velocity: SIMD3<Float>,
        time: Float,
        gravity: SIMD3<Float> = ArenaMetrics.gravity
    ) -> SIMD3<Float> {
        origin + velocity * time + 0.5 * gravity * time * time
    }

    static func samples(
        origin: SIMD3<Float>,
        velocity: SIMD3<Float>,
        gravity: SIMD3<Float> = ArenaMetrics.gravity,
        step: Float = 0.045,
        maxTime: Float = 0.95,
        floorY: Float = ArenaMetrics.tableSurfaceY - 0.02,
        reduced: Bool = false
    ) -> [SIMD3<Float>] {
        let dt = reduced ? step * 1.8 : step
        var time: Float = 0.05
        var points: [SIMD3<Float>] = []
        let limit = reduced ? 10 : 18
        while time <= maxTime && points.count < limit {
            let sample = point(origin: origin, velocity: velocity, time: time, gravity: gravity)
            if sample.y < floorY { break }
            if abs(sample.x) > 1.4 || abs(sample.z) > 1.9 { break }
            points.append(sample)
            time += dt
        }
        return points
    }

    static func defaultRack(towardNegativeZ: Bool) -> [SIMD3<Float>] {
        FormationLayout.make(.triangle, count: .six).worldPositions(ownerIsNear: !towardNegativeZ)
    }

    static func intendedLanding(
        aim: Float,
        power: Float,
        from origin: SIMD3<Float>,
        towardNegativeZ: Bool,
        physics: PhysicsConfiguration,
        cupTargets: [SIMD3<Float>],
        snapToNearestCup: Bool
    ) -> SIMD3<Float> {
        let cups = cupTargets.isEmpty ? defaultRack(towardNegativeZ: towardNegativeZ) : cupTargets
        let zs = cups.map(\.z)
        let xs = cups.map(\.x)
        let frontZ = towardNegativeZ ? (zs.max() ?? origin.z) : (zs.min() ?? origin.z)
        let backZ = towardNegativeZ ? (zs.min() ?? origin.z) : (zs.max() ?? origin.z)
        let rackHalfWidth = max(xs.map(abs).max() ?? 0.12, 0.10) + 0.028
        let towardThrower: Float = towardNegativeZ ? 1 : -1
        let shortZ = frontZ + towardThrower * 0.12
        let longZ = backZ - towardThrower * 0.05
        let aimWidth = rackHalfWidth + 0.09

        let clampedPower = max(physics.minLaunchPower, min(physics.maximumThrowForce, power))
        let span = max(0.01, physics.maximumThrowForce - physics.minLaunchPower)
        let depthT = ((clampedPower - physics.minLaunchPower) / span).clamped(to: 0...1)

        var target = SIMD3<Float>(
            aim.clamped(to: -1...1) * aimWidth,
            ArenaMetrics.tableSurfaceY + ArenaMetrics.cupHeight + 0.016,
            shortZ + (longZ - shortZ) * depthT
        )

        if snapToNearestCup, let nearest = cups.min(by: {
            hypotf($0.x - target.x, $0.z - target.z) < hypotf($1.x - target.x, $1.z - target.z)
        }) {
            let distance = hypotf(nearest.x - target.x, nearest.z - target.z)
            // Must be tighter than half cup spacing or every rack throw becomes a make.
            if distance < Self.aimAssistSnapRadius {
                let pull: Float = 0.45
                target.x += (nearest.x - target.x) * pull
                target.z += (nearest.z - target.z) * pull
            }
        }
        return target
    }

    static func throwVelocity(
        aim: Float,
        power: Float,
        from origin: SIMD3<Float>,
        towardNegativeZ: Bool,
        physics: PhysicsConfiguration,
        cupTargets: [SIMD3<Float>] = [],
        snapToNearestCup: Bool = false
    ) -> SIMD3<Float> {
        let target = intendedLanding(
            aim: aim,
            power: power,
            from: origin,
            towardNegativeZ: towardNegativeZ,
            physics: physics,
            cupTargets: cupTargets,
            snapToNearestCup: snapToNearestCup
        )
        let clampedPower = max(physics.minLaunchPower, min(physics.maximumThrowForce, power))
        let span = max(0.01, physics.maximumThrowForce - physics.minLaunchPower)
        let depthT = ((clampedPower - physics.minLaunchPower) / span).clamped(to: 0...1)
        let flight = 0.56 + (1 - depthT) * 0.08
        return initialVelocity(from: origin, to: target, flightTime: flight, gravity: physics.gravity)
    }
}
