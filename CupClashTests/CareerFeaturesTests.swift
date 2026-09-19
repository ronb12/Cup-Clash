import XCTest
@testable import CupClash

final class CareerFeaturesTests: XCTestCase {
    func testDailySeedIsStableForADate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 13))!
        XCTAssertEqual(DailyChallenge.dayID(for: date, calendar: calendar), "2026-09-13")
        XCTAssertEqual(DailyChallenge.seed(for: date, calendar: calendar), 20_260_913)
        let first = DailyChallenge.configuration(playerName: "Sam", aimAssistance: true, date: date, calendar: calendar)
        let second = DailyChallenge.configuration(playerName: "Sam", aimAssistance: true, date: date, calendar: calendar)
        XCTAssertEqual(first.mode, .dailyChallenge)
        XCTAssertEqual(first.seed, second.seed)
        XCTAssertEqual(first.difficulty, second.difficulty)
        XCTAssertEqual(first.cupCount, second.cupCount)
        XCTAssertEqual(first.formation, second.formation)
        XCTAssertTrue(first.mode.usesAI)
        XCTAssertTrue(first.mode.awardsCoins)
    }

    func testDailyScoreAddsWinBonus() {
        XCTAssertEqual(DailyChallenge.score(makes: 4, won: false), 40)
        XCTAssertEqual(DailyChallenge.score(makes: 4, won: true), 90)
    }

    func testSuddenDeathEndsAtThreeMakes() {
        var rules = MatchRulesEngine(
            configuration: MatchConfiguration(
                mode: .quickMatch,
                difficulty: .rookie,
                cupCount: .six,
                formation: .triangle,
                aimAssistance: false,
                playerName: "P1",
                opponentName: "P2",
                movingTargets: false,
                seed: 42,
                suddenDeathMakes: 3
            )
        )
        let cups = rules.state.cups.filter { $0.owner == .opponent && $0.isActive }
        XCTAssertGreaterThanOrEqual(cups.count, 3)
        for (index, cup) in cups.prefix(3).enumerated() {
            rules.state.activeSide = .player
            let resolution = rules.registerShot(.made, cupID: cup.id)
            if index < 2 {
                XCTAssertFalse(resolution.matchFinished)
            } else {
                XCTAssertTrue(resolution.matchFinished)
                XCTAssertEqual(resolution.winner, .player)
            }
        }
    }

    func testDailyWinPaysBonusCoins() {
        let config = DailyChallenge.configuration(
            playerName: "Sam",
            aimAssistance: false,
            date: Date(timeIntervalSince1970: 1_778_400_000)
        )
        let rewards = RewardCalculator.breakdown(
            configuration: config,
            playerWon: true,
            playerMakes: 3,
            bestStreak: 1,
            alreadyGranted: false
        )
        XCTAssertEqual(rewards.coins, config.difficulty.winCoins + 40)
        XCTAssertEqual(rewards.winXP, 75)
    }

    func testSuddenDeathWinPaysBonusCoins() {
        var config = MatchConfiguration.quickMatch(
            difficulty: .pro,
            cupCount: .six,
            aimAssistance: false,
            playerName: "Sam"
        )
        config.suddenDeathMakes = 3
        let rewards = RewardCalculator.breakdown(
            configuration: config,
            playerWon: true,
            playerMakes: 3,
            bestStreak: 1,
            alreadyGranted: false
        )
        XCTAssertEqual(rewards.coins, AIDifficulty.pro.winCoins + 15)
    }

    @MainActor
    func testLocalScoreboardRecordsDailyAndSuddenDeath() {
        let suite = "cupclash.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            return XCTFail("Could not create isolated defaults")
        }
        defaults.removePersistentDomain(forName: suite)
        let board = LocalScoreboard(defaults: defaults)
        let profile = PlayerProfile(displayName: "Sam", matchesWon: 2, shotsAttempted: 8, shotsMade: 5, bestWinningStreak: 2)

        let daily = DailyChallenge.configuration(playerName: "Sam", aimAssistance: false)
        let dailyResult = MatchResult(
            id: UUID(),
            configuration: daily,
            winner: .player,
            playerWon: true,
            playerCupsRemaining: 4,
            opponentCupsRemaining: 3,
            playerShots: 4,
            playerMakes: 3,
            opponentShots: 3,
            opponentMakes: 2,
            bestStreak: 2,
            perfectGame: false,
            rewards: RewardBreakdown(matchXP: 25, winXP: 75, cupXP: 15, streakXP: 0, coins: 60, levelUpCoins: 0, levelsGained: 0, alreadyGranted: false),
            startingTotalXP: 0,
            endingTotalXP: 115,
            startingLevel: 1,
            endingLevel: 1
        )
        board.record(result: dailyResult, playerName: "Sam", profile: profile)
        XCTAssertEqual(board.dailyBest()?.score, DailyChallenge.score(makes: 3, won: true))
        XCTAssertEqual(board.personalBest(for: GameCenterIDs.mostCareerWins), 2)

        var sudden = MatchConfiguration.quickMatch(difficulty: .rookie, cupCount: .six, aimAssistance: false, playerName: "Sam")
        sudden.suddenDeathMakes = 3
        let suddenResult = MatchResult(
            id: UUID(),
            configuration: sudden,
            winner: .player,
            playerWon: true,
            playerCupsRemaining: 6,
            opponentCupsRemaining: 3,
            playerShots: 3,
            playerMakes: 3,
            opponentShots: 2,
            opponentMakes: 1,
            bestStreak: 3,
            perfectGame: false,
            rewards: RewardBreakdown(matchXP: 25, winXP: 75, cupXP: 15, streakXP: 15, coins: 35, levelUpCoins: 0, levelsGained: 0, alreadyGranted: false),
            startingTotalXP: 0,
            endingTotalXP: 130,
            startingLevel: 1,
            endingLevel: 1
        )
        board.record(result: suddenResult, playerName: "Sam", profile: profile)
        XCTAssertEqual(board.suddenDeathWins(), 1)
        XCTAssertEqual(board.recentMatches().count, 2)

        let firstCup = AchievementDefinition.all.first { $0.id == GameCenterIDs.firstCup }!
        let clutch = AchievementDefinition.all.first { $0.id == GameCenterIDs.clutchFinish }!
        XCTAssertTrue(AchievementProgress.isComplete(for: firstCup, profile: profile, scoreboard: board))
        XCTAssertTrue(AchievementProgress.isComplete(for: clutch, profile: profile, scoreboard: board))
        defaults.removePersistentDomain(forName: suite)
    }

    func testLeaderboardCatalogCoversCareerModes() {
        let ids = Set(LeaderboardDefinition.all.map(\.id))
        XCTAssertTrue(ids.contains(GameCenterIDs.mostCareerWins))
        XCTAssertTrue(ids.contains(GameCenterIDs.dailyChallenge))
        XCTAssertTrue(ids.contains(GameCenterIDs.suddenDeathWins))
        XCTAssertTrue(ids.contains(GameCenterIDs.tournamentTitles))
        XCTAssertTrue(ids.contains(GameCenterIDs.challengesCleared))
        XCTAssertTrue(ids.contains(GameCenterIDs.weeklyTournament))
        XCTAssertEqual(AchievementDefinition.all.count, 12)
        XCTAssertEqual(ArenaStyle.catalog.count, 4)
        XCTAssertEqual(ArenaStyle.neonCourt.price, 0)
    }

    @MainActor
    func testRematchReplacesResultsAndFinishedGameplay() {
        let router = AppRouter()
        let config = MatchConfiguration.quickMatch(
            difficulty: .pro,
            cupCount: .six,
            aimAssistance: false,
            playerName: "Sam"
        )
        router.push(.matchSetup(.quickMatch))
        router.start(config)
        router.showResults(
            MatchResult(
                id: UUID(),
                configuration: config,
                winner: .player,
                playerWon: true,
                playerCupsRemaining: 4,
                opponentCupsRemaining: 0,
                playerShots: 6,
                playerMakes: 6,
                opponentShots: 5,
                opponentMakes: 2,
                bestStreak: 3,
                perfectGame: true,
                rewards: RewardBreakdown(
                    matchXP: 25,
                    winXP: 75,
                    cupXP: 30,
                    streakXP: 15,
                    coins: 35,
                    levelUpCoins: 0,
                    levelsGained: 0,
                    alreadyGranted: false
                ),
                startingTotalXP: 0,
                endingTotalXP: 145,
                startingLevel: 1,
                endingLevel: 1
            )
        )
        XCTAssertEqual(router.path.count, 3)
        router.rematch(config)
        XCTAssertEqual(router.path.count, 2)
    }
}
