import Foundation
import simd

enum TrajectoryCalculator {
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

    static func throwVelocity(
        aim: Float,
        power: Float,
        from origin: SIMD3<Float>,
        towardNegativeZ: Bool,
        physics: PhysicsConfiguration,
        aimAssistTargetX: Float?
    ) -> SIMD3<Float> {
        let clampedPower = max(physics.minimumThrowForce, min(physics.maximumThrowForce, power))
        let forwardSign: Float = towardNegativeZ ? -1 : 1
        let travel = 1.05 + clampedPower * 1.05
        var targetX = aim * physics.sideAimMultiplier * 1.15
        if let assist = aimAssistTargetX, abs(assist - targetX) < 0.12 {
            targetX = targetX * 0.72 + assist * 0.28
        }
        let target = SIMD3<Float>(
            targetX,
            ArenaMetrics.tableSurfaceY + ArenaMetrics.cupHeight * 0.46,
            origin.z + forwardSign * travel
        )
        let flight = 0.46 + (1 - clampedPower) * 0.10
        return initialVelocity(from: origin, to: target, flightTime: flight, gravity: physics.gravity)
    }
}
