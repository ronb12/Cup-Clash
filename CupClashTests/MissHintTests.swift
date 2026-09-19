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
}
