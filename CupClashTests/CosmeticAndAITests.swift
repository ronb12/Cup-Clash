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

    @MainActor
    func testAimPersistsAfterEndDrag() {
        let input = ThrowInputController()
        input.begin()
        input.update(translation: CGSize(width: -90, height: 180), sensitivity: 1, leftHanded: false)
        XCTAssertLessThan(input.aim, -0.2)
        XCTAssertGreaterThan(input.power, 0.4)
        input.endDrag()
        XCTAssertLessThan(input.aim, -0.2)
        XCTAssertGreaterThan(input.power, 0.4)
        XCTAssertFalse(input.isAiming)
    }

    func testLeftAimProducesNegativeXVelocity() {
        let origin = SIMD3<Float>(0, ArenaMetrics.throwOriginY, 0.8)
        let left = TrajectoryCalculator.throwVelocity(
            aim: -1,
            power: 0.7,
            from: origin,
            towardNegativeZ: true,
            physics: .playable
        )
        let right = TrajectoryCalculator.throwVelocity(
            aim: 1,
            power: 0.7,
            from: origin,
            towardNegativeZ: true,
            physics: .playable
        )
        XCTAssertLessThan(left.x, -0.15)
        XCTAssertGreaterThan(right.x, 0.15)
        XCTAssertLessThan(left.z, 0)
        XCTAssertLessThan(right.z, 0)
    }

    func testMaxPowerLandsInOpponentRack() {
        let origin = AIPlayerController.throwOrigin(for: .player)
        let cups = TrajectoryCalculator.defaultRack(towardNegativeZ: true)
        let landing = TrajectoryCalculator.intendedLanding(
            aim: 0,
            power: 1,
            from: origin,
            towardNegativeZ: true,
            physics: .playable,
            cupTargets: cups,
            snapToNearestCup: true
        )
        let frontZ = cups.map(\.z).max() ?? 0
        let backZ = cups.map(\.z).min() ?? 0
        XCTAssertLessThan(abs(landing.x), 0.16)
        XCTAssertLessThanOrEqual(landing.z, frontZ + 0.02)
        XCTAssertGreaterThanOrEqual(landing.z, backZ - 0.08)
        XCTAssertGreaterThan(landing.z, -ArenaMetrics.tableHalfLength)
    }

    func testFullSideAimStaysOnTable() {
        let origin = AIPlayerController.throwOrigin(for: .player)
        let landing = TrajectoryCalculator.intendedLanding(
            aim: 1,
            power: 0.7,
            from: origin,
            towardNegativeZ: true,
            physics: .playable,
            cupTargets: [],
            snapToNearestCup: false
        )
        XCTAssertLessThan(abs(landing.x), ArenaMetrics.tableHalfWidth)
    }

    func testAimAssistNudgesNearMissesButDoesNotTeleport() {
        let origin = AIPlayerController.throwOrigin(for: .player)
        let cups = TrajectoryCalculator.defaultRack(towardNegativeZ: true)
        let raw = TrajectoryCalculator.intendedLanding(
            aim: 0.08,
            power: 0.55,
            from: origin,
            towardNegativeZ: true,
            physics: .playable,
            cupTargets: cups,
            snapToNearestCup: false
        )
        let assisted = TrajectoryCalculator.intendedLanding(
            aim: 0.08,
            power: 0.55,
            from: origin,
            towardNegativeZ: true,
            physics: .playable,
            cupTargets: cups,
            snapToNearestCup: true
        )
        let rawGap = cups.map { hypotf($0.x - raw.x, $0.z - raw.z) }.min() ?? 1
        let assistedGap = cups.map { hypotf($0.x - assisted.x, $0.z - assisted.z) }.min() ?? 1
        if rawGap < TrajectoryCalculator.aimAssistSnapRadius {
            XCTAssertLessThan(assistedGap, rawGap)
            XCTAssertGreaterThan(assistedGap, 0.001)
        }
        XCTAssertGreaterThan(assisted.y, ArenaMetrics.tableSurfaceY + ArenaMetrics.cupHeight)
    }

    func testRackThrowWithoutAssistIsNotGuaranteedMake() {
        let origin = AIPlayerController.throwOrigin(for: .player)
        let cups = TrajectoryCalculator.defaultRack(towardNegativeZ: true)
        let landing = TrajectoryCalculator.intendedLanding(
            aim: 0.42,
            power: 0.22,
            from: origin,
            towardNegativeZ: true,
            physics: .playable,
            cupTargets: cups,
            snapToNearestCup: false
        )
        let nearest = cups.map { hypotf($0.x - landing.x, $0.z - landing.z) }.min() ?? 0
        XCTAssertGreaterThan(nearest, ArenaMetrics.cupTopRadius)
    }

    func testWideAimAssistDoesNotCoverWholeRack() {
        let origin = AIPlayerController.throwOrigin(for: .player)
        let cups = TrajectoryCalculator.defaultRack(towardNegativeZ: true)
        let landing = TrajectoryCalculator.intendedLanding(
            aim: 0.85,
            power: 0.18,
            from: origin,
            towardNegativeZ: true,
            physics: .playable,
            cupTargets: cups,
            snapToNearestCup: true
        )
        let nearest = cups.map { hypotf($0.x - landing.x, $0.z - landing.z) }.min() ?? 0
        XCTAssertGreaterThan(nearest, TrajectoryCalculator.aimAssistSnapRadius)
    }

    func testAimAssistRadiusIsTighterThanCupSpacing() {
        XCTAssertLessThan(TrajectoryCalculator.aimAssistSnapRadius, ArenaMetrics.cupSpacing / 2)
    }

    @MainActor
    func testCameraOrbitGoesAroundTheTable() {
        let start = GameCameraController.aimingPose(for: .player)
        let end = GameCameraController.aimingPose(for: .opponent)
        let mid = GameCameraController.orbitPose(from: start, to: end, t: 0.5)
        XCTAssertGreaterThan(start.position.z, 1)
        XCTAssertLessThan(end.position.z, -1)
        XCTAssertGreaterThan(abs(mid.position.x), 1.2)
        XCTAssertLessThan(abs(mid.position.z), 1.0)
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
