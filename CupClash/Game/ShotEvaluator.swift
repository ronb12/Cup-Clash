import Foundation
import simd

struct ShotEvaluation: Equatable, Sendable {
    var result: ShotResult?
    var cupID: UUID?
}

@MainActor
final class ShotEvaluator {
    private var generation = 0
    private var scoredGenerations: Set<Int> = []
    private var triggerCup: UUID?
    private var triggerEnteredAt: Date?
    private var hitTable = false
    private var hitRim = false
    private var launchedAt: Date?
    private var lowSpeedSince: Date?
    private let physics: PhysicsConfiguration

    init(physics: PhysicsConfiguration) {
        self.physics = physics
    }

    func beginShot(generation: Int) {
        self.generation = generation
        triggerCup = nil
        triggerEnteredAt = nil
        hitTable = false
        hitRim = false
        launchedAt = Date()
        lowSpeedSince = nil
    }

    func noteTableHit() {
        hitTable = true
    }

    func noteRimHit() {
        hitRim = true
    }

    func enterTrigger(cupID: UUID) {
        guard !scoredGenerations.contains(generation) else { return }
        if triggerCup != cupID {
            triggerCup = cupID
            triggerEnteredAt = Date()
        }
    }

    func exitTrigger(cupID: UUID) {
        if triggerCup == cupID {
            triggerCup = nil
            triggerEnteredAt = nil
        }
    }

    func evaluate(position: SIMD3<Float>, speed: Float, now: Date = Date()) -> ShotEvaluation {
        guard let launchedAt, !scoredGenerations.contains(generation) else {
            return ShotEvaluation(result: nil, cupID: nil)
        }

        if let cupID = triggerCup {
            let inMouth = position.y <= ArenaMetrics.tableSurfaceY + ArenaMetrics.cupHeight + 0.02
                && position.y >= ArenaMetrics.tableSurfaceY + 0.01
            if inMouth {
                if speed <= physics.inCupSpeed {
                    return finish(.made, cupID: cupID)
                }
                if let entered = triggerEnteredAt, now.timeIntervalSince(entered) >= physics.scoreHoldDuration {
                    return finish(.made, cupID: cupID)
                }
            }
        }

        let elapsed = now.timeIntervalSince(launchedAt)
        if elapsed < physics.scoreGraceDuration {
            return ShotEvaluation(result: nil, cupID: nil)
        }

        if abs(position.x) > physics.outOfBoundsX || abs(position.z) > physics.outOfBoundsZ || position.y < physics.outOfBoundsY {
            return finish(.outOfBounds, cupID: nil)
        }

        if elapsed >= physics.shotTimeout {
            return finish(.timeout, cupID: nil)
        }

        if speed < physics.settleSpeed && triggerCup == nil {
            if lowSpeedSince == nil {
                lowSpeedSince = now
            }
            if let lowSpeedSince, now.timeIntervalSince(lowSpeedSince) >= physics.settleDuration {
                if hitRim { return finish(.rimOut, cupID: nil) }
                if hitTable { return finish(.tableBounce, cupID: nil) }
                return finish(.missed, cupID: nil)
            }
        } else {
            lowSpeedSince = nil
        }

        return ShotEvaluation(result: nil, cupID: nil)
    }

    private func finish(_ result: ShotResult, cupID: UUID?) -> ShotEvaluation {
        scoredGenerations.insert(generation)
        return ShotEvaluation(result: result, cupID: cupID)
    }
}
