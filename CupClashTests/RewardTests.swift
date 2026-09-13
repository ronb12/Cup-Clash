import XCTest
@testable import CupClash

final class RewardTests: XCTestCase {
    func testQuickMatchWinCoins() {
        let config = MatchConfiguration.quickMatch(
            difficulty: .champion,
            cupCount: .six,
            aimAssistance: true,
            playerName: "Sam"
        )
        let rewards = RewardCalculator.breakdown(
            configuration: config,
            playerWon: true,
            playerMakes: 6,
            bestStreak: 3,
            alreadyGranted: false
        )
        XCTAssertEqual(rewards.matchXP, 25)
        XCTAssertEqual(rewards.winXP, 75)
        XCTAssertEqual(rewards.cupXP, 30)
        XCTAssertEqual(rewards.streakXP, 15)
        XCTAssertEqual(rewards.coins, 50)
    }

    func testPracticeHasNoRewards() {
        var config = MatchConfiguration.quickMatch(difficulty: .rookie, cupCount: .six, aimAssistance: false, playerName: "Sam")
        config.mode = .practice
        let rewards = RewardCalculator.breakdown(
            configuration: config,
            playerWon: true,
            playerMakes: 8,
            bestStreak: 4,
            alreadyGranted: false
        )
        XCTAssertEqual(rewards.totalXP, 0)
        XCTAssertEqual(rewards.coins, 0)
    }

    func testPassAndPlayHasNoCoins() {
        var config = MatchConfiguration.quickMatch(difficulty: .pro, cupCount: .ten, aimAssistance: false, playerName: "A")
        config.mode = .passAndPlay
        let rewards = RewardCalculator.breakdown(
            configuration: config,
            playerWon: true,
            playerMakes: 4,
            bestStreak: 1,
            alreadyGranted: false
        )
        XCTAssertEqual(rewards.coins, 0)
        XCTAssertEqual(rewards.matchXP, 25)
    }

    func testAlreadyGrantedPreventsRewards() {
        let config = MatchConfiguration.quickMatch(difficulty: .pro, cupCount: .six, aimAssistance: true, playerName: "Sam")
        let rewards = RewardCalculator.breakdown(
            configuration: config,
            playerWon: true,
            playerMakes: 6,
            bestStreak: 6,
            alreadyGranted: true
        )
        XCTAssertTrue(rewards.alreadyGranted)
        XCTAssertEqual(rewards.totalXP, 0)
    }

    func testLevelUpCoins() {
        let base = RewardBreakdown(matchXP: 250, winXP: 0, cupXP: 0, streakXP: 0, coins: 0, levelUpCoins: 0, levelsGained: 0, alreadyGranted: false)
        let applied = RewardCalculator.applyingLevelUps(to: base, startingTotalXP: 0)
        XCTAssertEqual(applied.levelsGained, 1)
        XCTAssertEqual(applied.levelUpCoins, 50)
    }

    func testAccuracy() {
        XCTAssertEqual(AccuracyMath.percent(made: 0, attempted: 0), 0)
        XCTAssertEqual(AccuracyMath.percent(made: 1, attempted: 4), 25)
    }
}
