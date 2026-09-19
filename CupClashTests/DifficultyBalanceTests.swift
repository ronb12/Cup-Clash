import XCTest
import simd
@testable import CupClash

/// Guards the AI's real difficulty. Simulates its shots kinematically (the launch path is
/// compensated so real physics match) and counts landings inside a cup's scoring window.
final class DifficultyBalanceTests: XCTestCase {
    private func hitRate(_ level: AIDifficulty, cups: [CupData], samples: Int = 3000) -> Double {
        let rimY = ArenaMetrics.tableSurfaceY + ArenaMetrics.cupHeight + 0.016
        let window = ArenaMetrics.cupTopRadius - ArenaMetrics.ballRadius
        var hits = 0
        for _ in 0..<samples {
            guard let plan = AIPlayerController.planThrow(difficulty: level, cups: cups, throwingSide: .opponent) else { continue }
            var t: Float = 0.02
            var prev = plan.origin
            var crossing = plan.origin
            while t < 1.5 {
                let point = TrajectoryCalculator.point(origin: plan.origin, velocity: plan.velocity, time: t)
                if prev.y > rimY, point.y <= rimY, t > 0.2 { crossing = point; break }
                prev = point
                t += 0.002
            }
            let nearest = cups.map { hypotf($0.worldPosition.x - crossing.x, $0.worldPosition.z - crossing.z) }.min() ?? 9
            if nearest <= window { hits += 1 }
        }
        return Double(hits) / Double(samples)
    }

    private var rack: [CupData] {
        MatchRulesEngine.makeCups(owner: .player, layout: FormationLayout.make(.triangle, count: .six), nearSide: true)
    }

    func testHitRatesRiseWithDifficulty() {
        let rookie = hitRate(.rookie, cups: rack)
        let pro = hitRate(.pro, cups: rack)
        let champion = hitRate(.champion, cups: rack)
        XCTAssertLessThan(rookie, pro)
        XCTAssertLessThan(pro, champion)
    }

    func testRookieIsBeatableProIsAChallengeChampionIsHard() {
        XCTAssertTrue((0.12...0.40).contains(hitRate(.rookie, cups: rack)), "Rookie should be beatable")
        XCTAssertTrue((0.40...0.70).contains(hitRate(.pro, cups: rack)), "Pro should be a real challenge")
        XCTAssertGreaterThanOrEqual(hitRate(.champion, cups: rack), 0.72, "Champion should be hard")
    }
}
