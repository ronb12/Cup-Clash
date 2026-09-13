import Foundation
import simd

struct AIDifficultyParameters: Equatable, Sendable {
    var aimSpread: ClosedRange<Float>
    var powerSpread: ClosedRange<Float>
    var flightTime: ClosedRange<Float>
    var missBias: Float
    var bankChance: Float
    var thinkTime: ClosedRange<Double>
}

extension AIDifficulty {
    var parameters: AIDifficultyParameters {
        switch self {
        case .rookie:
            AIDifficultyParameters(
                aimSpread: -0.18...0.18,
                powerSpread: -0.24...0.22,
                flightTime: 0.48...0.66,
                missBias: 0.30,
                bankChance: 0.06,
                thinkTime: 0.55...1.15
            )
        case .pro:
            AIDifficultyParameters(
                aimSpread: -0.09...0.09,
                powerSpread: -0.12...0.10,
                flightTime: 0.50...0.58,
                missBias: 0.12,
                bankChance: 0.22,
                thinkTime: 0.38...0.82
            )
        case .champion:
            AIDifficultyParameters(
                aimSpread: -0.038...0.038,
                powerSpread: -0.05...0.05,
                flightTime: 0.50...0.55,
                missBias: 0.05,
                bankChance: 0.14,
                thinkTime: 0.26...0.55
            )
        }
    }
}

struct PlannedThrow: Equatable, Sendable {
    var origin: SIMD3<Float>
    var velocity: SIMD3<Float>
    var thinkTime: Double
}

enum AIPlayerController {
    static func planThrow(
        difficulty: AIDifficulty,
        cups: [CupData],
        throwingSide: PlayerSide,
        physics: PhysicsConfiguration = .playable
    ) -> PlannedThrow? {
        let targets = cups.filter { $0.owner == throwingSide.opposite && $0.isActive }
        guard let cup = targets.randomElement() else { return nil }
        let params = difficulty.parameters
        let origin = throwOrigin(for: throwingSide)
        var target = cup.worldPosition
        target.y = ArenaMetrics.tableSurfaceY + ArenaMetrics.cupHeight * 0.42
        target.x += Float.random(in: params.aimSpread)
        target.z += Float.random(in: params.powerSpread) * 0.35

        if Float.random(in: 0...1) < params.missBias {
            target.z += throwingSide == .player ? 0.22 : -0.22
            target.x += Float.random(in: -0.12...0.12)
        }

        if Float.random(in: 0...1) < params.bankChance {
            let toward: Float = throwingSide == .player ? -1 : 1
            target.z += toward * -0.16
            target.y = ArenaMetrics.tableSurfaceY + ArenaMetrics.ballRadius + 0.01
        }

        let flight = Float.random(in: params.flightTime)
        let velocity = TrajectoryCalculator.initialVelocity(
            from: origin,
            to: target,
            flightTime: flight,
            gravity: physics.gravity
        )
        return PlannedThrow(
            origin: origin,
            velocity: velocity,
            thinkTime: Double.random(in: params.thinkTime)
        )
    }

    static func throwOrigin(for side: PlayerSide) -> SIMD3<Float> {
        let z = side == .player
            ? ArenaMetrics.tableHalfLength - ArenaMetrics.throwStandOff
            : -ArenaMetrics.tableHalfLength + ArenaMetrics.throwStandOff
        return SIMD3(0, ArenaMetrics.throwOriginY, z)
    }
}
