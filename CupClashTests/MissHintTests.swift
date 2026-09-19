import XCTest
import simd
@testable import CupClash

final class MissHintTests: XCTestCase {
    private let cups: [SIMD3<Float>] = [
        SIMD3(-0.05, 0.9, -0.9), SIMD3(0.05, 0.9, -0.9),
        SIMD3(0, 0.9, -1.0)
    ]

    func testShortLandingSuggestsMorePower() {
        let hint = MissHint.describe(landing: SIMD3(0, 0.8, -0.4), cups: cups, towardNegativeZ: true)
        XCTAssertEqual(hint, "Short — add power")
    }

    func testLongLandingSuggestsLessPower() {
        let hint = MissHint.describe(landing: SIMD3(0, 0.8, -1.3), cups: cups, towardNegativeZ: true)
        XCTAssertEqual(hint, "Long — ease off")
    }

    func testSideMissNamesTheDirection() {
        XCTAssertEqual(MissHint.describe(landing: SIMD3(0.2, 0.8, -0.95), cups: cups, towardNegativeZ: true), "Too far right")
        XCTAssertEqual(MissHint.describe(landing: SIMD3(-0.2, 0.8, -0.95), cups: cups, towardNegativeZ: true), "Too far left")
    }

    func testDirectionFlipsWhenThrowingFromOtherEnd() {
        let flipped = cups.map { SIMD3<Float>($0.x, $0.y, -$0.z) }
        XCTAssertEqual(MissHint.describe(landing: SIMD3(0.2, 0.8, 0.95), cups: flipped, towardNegativeZ: false), "Too far left")
    }

    func testCloseMissHasNoHint() {
        XCTAssertNil(MissHint.describe(landing: SIMD3(0.06, 0.8, -0.95), cups: cups, towardNegativeZ: true))
    }

    func testLosingRankedMatchEarnsCappedConsolationCoins() {
        let config = MatchConfiguration.quickMatch(difficulty: .pro, cupCount: .six, aimAssistance: true, playerName: "Sam")
        let some = RewardCalculator.breakdown(configuration: config, playerWon: false, playerMakes: 3, bestStreak: 1, alreadyGranted: false)
        XCTAssertEqual(some.coins, 9)
        let many = RewardCalculator.breakdown(configuration: config, playerWon: false, playerMakes: 9, bestStreak: 1, alreadyGranted: false)
        XCTAssertEqual(many.coins, AppConstants.consolationCoinCap)
        let none = RewardCalculator.breakdown(configuration: config, playerWon: false, playerMakes: 0, bestStreak: 0, alreadyGranted: false)
        XCTAssertEqual(none.coins, 0)
    }

    func testOnTargetOnlyWhenLandingIsInsideAMouth() {
        XCTAssertTrue(TrajectoryCalculator.isOnTarget(landing: SIMD3(0.06, 0.9, -0.91), cups: cups))
        XCTAssertFalse(TrajectoryCalculator.isOnTarget(landing: SIMD3(0, 0.9, -0.80), cups: cups))
        XCTAssertFalse(TrajectoryCalculator.isOnTarget(landing: SIMD3(0.2, 0.9, -0.9), cups: cups))
    }
}

final class AimAssistPolicyTests: XCTestCase {
    private func config(_ mode: GameMode, _ level: AIDifficulty, locked: Bool = false) -> MatchConfiguration {
        var c = MatchConfiguration.quickMatch(difficulty: level, cupCount: .six, aimAssistance: true, playerName: "Sam")
        c.mode = mode
        c.lockAimAssistOff = locked
        return c
    }

    func testOnlyRookieDefaultsToAssist() {
        XCTAssertTrue(AimAssistPolicy.defaultEnabled(for: .rookie))
        XCTAssertFalse(AimAssistPolicy.defaultEnabled(for: .pro))
        XCTAssertFalse(AimAssistPolicy.defaultEnabled(for: .champion))
    }

    func testProAndChampionNeverAllowAssist() {
        XCTAssertFalse(config(.quickMatch, .champion).aimAssistActive)
        XCTAssertFalse(config(.quickMatch, .pro).aimAssistActive)
        XCTAssertFalse(config(.challenge, .pro).aimAssistActive)
    }

    func testRookieAllowsAssistWhenRequested() {
        XCTAssertTrue(config(.quickMatch, .rookie).aimAssistActive)
    }

    func testRankedModesLockAssistOff() {
        XCTAssertFalse(config(.tournament, .rookie).aimAssistActive)
        XCTAssertFalse(config(.dailyChallenge, .rookie).aimAssistActive)
    }

    func testChallengeLockIsRespected() {
        XCTAssertFalse(config(.challenge, .rookie, locked: true).aimAssistActive)
        XCTAssertTrue(config(.challenge, .rookie, locked: false).aimAssistActive)
    }

    func testRequestedOffStaysOffEvenWhenAllowed() {
        var c = config(.quickMatch, .rookie)
        c.aimAssistance = false
        XCTAssertFalse(c.aimAssistActive)
    }

    func testPassAndPlayIgnoresDifficulty() {
        XCTAssertTrue(config(.passAndPlay, .champion).aimAssistActive)
    }

    func testOnTargetCueOnlyOnRookieAndUnlockedModes() {
        XCTAssertTrue(config(.quickMatch, .rookie).showsOnTargetCue)
        XCTAssertFalse(config(.quickMatch, .pro).showsOnTargetCue)
        XCTAssertFalse(config(.quickMatch, .champion).showsOnTargetCue)
        XCTAssertFalse(config(.tournament, .rookie).showsOnTargetCue)
    }
}

final class FixedPowerScaleTests: XCTestCase {
    private let origin = AIPlayerController.throwOrigin(for: .player)
    private var fullRack: [SIMD3<Float>] {
        FormationLayout.make(.triangle, count: .six).worldPositions(ownerIsNear: false)
    }

    private func landing(power: Float, cups: [SIMD3<Float>], reach: TrajectoryCalculator.ThrowReach?) -> SIMD3<Float> {
        TrajectoryCalculator.intendedLanding(
            aim: 0, power: power, from: origin, towardNegativeZ: true,
            physics: .playable, cupTargets: cups, snapToNearestCup: false, reach: reach
        )
    }

    func testSamePowerLandsInTheSamePlaceWhateverCupsRemain() {
        let reach = TrajectoryCalculator.reach(of: fullRack, towardNegativeZ: true)
        let backThree = Array(fullRack.sorted { $0.z < $1.z }.prefix(3))
        for power in stride(from: Float(0.3), through: 1.0, by: 0.1) {
            let full = landing(power: power, cups: fullRack, reach: reach)
            let few = landing(power: power, cups: backThree, reach: reach)
            XCTAssertEqual(full.z, few.z, accuracy: 0.0001, "power \(power)")
            XCTAssertEqual(full.x, few.x, accuracy: 0.0001, "power \(power)")
        }
    }

    func testWithoutFixedReachTheScaleShiftsWithRemainingCups() {
        let backThree = Array(fullRack.sorted { $0.z < $1.z }.prefix(3))
        let full = landing(power: 0.5, cups: fullRack, reach: nil)
        let few = landing(power: 0.5, cups: backThree, reach: nil)
        XCTAssertNotEqual(full.z, few.z, accuracy: 0.01)
    }

    func testReachCoversTheWholeRack() throws {
        let reach = try XCTUnwrap(TrajectoryCalculator.reach(of: fullRack, towardNegativeZ: true))
        XCTAssertGreaterThan(reach.frontZ, reach.backZ) // front is nearer the +z thrower
        for cup in fullRack {
            XCTAssertLessThanOrEqual(cup.z, reach.frontZ + 0.0001)
            XCTAssertGreaterThanOrEqual(cup.z, reach.backZ - 0.0001)
            XCTAssertLessThanOrEqual(abs(cup.x), reach.halfWidth)
        }
    }
}
