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
}
