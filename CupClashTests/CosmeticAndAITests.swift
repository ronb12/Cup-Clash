import XCTest
@testable import CupClash

final class CosmeticAndAITests: XCTestCase {
    func testPurchaseDeductsCoins() {
        let result = CosmeticStore.purchase(itemID: "ball.cyan", price: 150, coins: 200, unlocked: ["ball.classic"])
        XCTAssertEqual(result.result, .purchased)
        XCTAssertEqual(result.coins, 50)
        XCTAssertTrue(result.unlocked.contains("ball.cyan"))
    }

    func testInsufficientCoins() {
        let result = CosmeticStore.purchase(itemID: "ball.gold", price: 500, coins: 40, unlocked: ["ball.classic"])
        XCTAssertEqual(result.result, .notEnoughCoins)
        XCTAssertEqual(result.coins, 40)
        XCTAssertFalse(result.unlocked.contains("ball.gold"))
    }

    func testAlreadyOwned() {
        let result = CosmeticStore.purchase(itemID: "ball.classic", price: 0, coins: 10, unlocked: ["ball.classic"])
        XCTAssertEqual(result.result, .alreadyOwned)
    }

    func testFormationsHaveExpectedCounts() {
        XCTAssertEqual(FormationLayout.make(.triangle, count: .six, seed: 1).offsets.count, 6)
        XCTAssertEqual(FormationLayout.make(.triangle, count: .ten, seed: 1).offsets.count, 10)
        XCTAssertEqual(FormationLayout.make(.diamond, count: .six, seed: 1).offsets.count, 6)
        XCTAssertEqual(FormationLayout.make(.straight, count: .ten, seed: 1).offsets.count, 10)
        XCTAssertEqual(FormationLayout.make(.randomized, count: .six, seed: 99).offsets.count, 6)
    }

    func testAIParameterRanges() {
        XCTAssertGreaterThan(AIDifficulty.rookie.parameters.aimSpread.upperBound, AIDifficulty.champion.parameters.aimSpread.upperBound)
        XCTAssertGreaterThan(AIDifficulty.rookie.parameters.missBias, AIDifficulty.pro.parameters.missBias)
        XCTAssertGreaterThan(AIDifficulty.pro.parameters.missBias, AIDifficulty.champion.parameters.missBias)
        XCTAssertGreaterThan(AIDifficulty.pro.parameters.bankChance, AIDifficulty.rookie.parameters.bankChance)
    }

    func testAIPlansRealVelocity() {
        let layout = FormationLayout.make(.triangle, count: .six, seed: 3)
        let cups = MatchRulesEngine.makeCups(owner: .player, layout: layout, nearSide: true)
            + MatchRulesEngine.makeCups(owner: .opponent, layout: layout, nearSide: false)
        let plan = AIPlayerController.planThrow(difficulty: .pro, cups: cups, throwingSide: .opponent)
        XCTAssertNotNil(plan)
        XCTAssertGreaterThan(plan?.velocity.length ?? 0, 1.5)
    }

    func testTrajectorySamplesStayReasonable() {
        let origin = SIMD3<Float>(0, 0.88, 0.8)
        let velocity = TrajectoryCalculator.initialVelocity(from: origin, to: SIMD3(0, 0.84, -1.0), flightTime: 0.52)
        let points = TrajectoryCalculator.samples(origin: origin, velocity: velocity)
        XCTAssertFalse(points.isEmpty)
        XCTAssertLessThan(points.count, 20)
        XCTAssertGreaterThan(velocity.y, 0)
    }
}
