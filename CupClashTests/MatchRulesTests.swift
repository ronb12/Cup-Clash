import XCTest
@testable import CupClash

final class MatchRulesTests: XCTestCase {
    private func engine(mode: GameMode = .quickMatch, count: CupCount = .six) -> MatchRulesEngine {
        MatchRulesEngine(
            configuration: MatchConfiguration(
                mode: mode,
                difficulty: .rookie,
                cupCount: count,
                formation: .triangle,
                aimAssistance: false,
                playerName: "P1",
                opponentName: "P2",
                movingTargets: false,
                seed: 42
            )
        )
    }

    func testInitialTurnIsPlayer() {
        let rules = engine()
        XCTAssertEqual(rules.state.activeSide, .player)
        XCTAssertEqual(rules.state.playerCupsRemaining, 6)
        XCTAssertEqual(rules.state.opponentCupsRemaining, 6)
    }

    func testTurnPassesAfterMiss() {
        var rules = engine()
        let resolution = rules.registerShot(.missed, cupID: nil)
        XCTAssertEqual(resolution.nextSide, .opponent)
        XCTAssertEqual(rules.state.activeSide, .opponent)
        XCTAssertEqual(rules.state.playerShots, 1)
        XCTAssertEqual(rules.state.currentMakeStreak, 0)
    }

    func testCupRemovedAndDuplicateIgnored() {
        var rules = engine()
        let target = rules.state.cups.first { $0.owner == .opponent && $0.isActive }
        guard let cup = target else {
            return XCTFail("Missing cup")
        }
        let first = rules.registerShot(.made, cupID: cup.id)
        XCTAssertEqual(first.scoredCupID, cup.id)
        XCTAssertEqual(rules.state.playerMakes, 1)
        XCTAssertFalse(rules.state.cups.first(where: { $0.id == cup.id })?.isActive ?? true)

        rules.state.activeSide = .player
        let second = rules.registerShot(.made, cupID: cup.id)
        XCTAssertNil(second.scoredCupID)
        XCTAssertEqual(rules.state.playerMakes, 1)
    }

    func testWinnerWhenAllOpponentCupsCleared() {
        var rules = engine()
        let cups = rules.state.cups.filter { $0.owner == .opponent }
        for (index, cup) in cups.enumerated() {
            rules.state.activeSide = .player
            let resolution = rules.registerShot(.made, cupID: cup.id)
            if index == cups.count - 1 {
                XCTAssertTrue(resolution.matchFinished)
                XCTAssertEqual(resolution.winner, .player)
            }
        }
    }

    func testPracticeNeverEnds() {
        var rules = engine(mode: .practice)
        let cups = rules.state.cups.filter { $0.owner == .opponent }
        for cup in cups {
            let resolution = rules.registerShot(.made, cupID: cup.id)
            XCTAssertFalse(resolution.matchFinished)
        }
        XCTAssertEqual(rules.state.activeSide, .player)
    }

    func testPassAndPlayRequestsOverlay() {
        var rules = engine(mode: .passAndPlay)
        let resolution = rules.registerShot(.tableBounce, cupID: nil)
        XCTAssertTrue(resolution.shouldOfferPassOverlay)
        XCTAssertTrue(rules.state.awaitingPassReady)
        rules.acknowledgePassReady()
        XCTAssertFalse(rules.state.awaitingPassReady)
    }

    @MainActor
    func testShotEvaluatorReportsAMissOnlyOnce() {
        let evaluator = ShotEvaluator(physics: .playable)
        evaluator.beginShot(generation: 7)
        evaluator.noteTableHit()
        let still = SIMD3<Float>(0, ArenaMetrics.tableSurfaceY + 0.02, 0)
        let start = Date()
        _ = evaluator.evaluate(position: still, speed: 0, now: start.addingTimeInterval(0.25))
        let first = evaluator.evaluate(position: still, speed: 0, now: start.addingTimeInterval(0.72))
        let second = evaluator.evaluate(position: still, speed: 0, now: start.addingTimeInterval(0.82))
        XCTAssertEqual(first.result, .tableBounce)
        XCTAssertNil(second.result)
    }

    @MainActor
    func testBallInsideCupCountsAsAMake() {
        let evaluator = ShotEvaluator(physics: .playable)
        evaluator.beginShot(generation: 3)
        let cupID = UUID()
        evaluator.enterTrigger(cupID: cupID)
        let inside = SIMD3<Float>(
            0,
            ArenaMetrics.tableSurfaceY + ArenaMetrics.cupHeight * 0.45,
            -1.0
        )
        let made = evaluator.evaluate(position: inside, speed: 0.2)
        XCTAssertEqual(made.result, .made)
        XCTAssertEqual(made.cupID, cupID)
    }

    func testRerackOnlyOnceWhenThreeRemain() {
        var rules = engine()
        let own = rules.state.cups.indices.filter { rules.state.cups[$0].owner == .player }
        for index in own.dropFirst(3) {
            rules.state.cups[index].isActive = false
        }
        XCTAssertTrue(rules.requestRerack(for: .player))
        XCTAssertFalse(rules.requestRerack(for: .player))
    }
}
