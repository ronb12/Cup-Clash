import XCTest
@testable import CupClash

final class TournamentAndChallengeTests: XCTestCase {
    func testWeeklyBracketIsStableForADate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 13))!
        let first = TournamentEvent.current(date: date, calendar: calendar)
        let second = TournamentEvent.current(date: date, calendar: calendar)
        XCTAssertEqual(first.weekID, second.weekID)
        XCTAssertEqual(first.title, second.title)
        XCTAssertEqual(first.rounds.count, 3)
        XCTAssertEqual(first.rounds.map(\.opponentName), second.rounds.map(\.opponentName))
        XCTAssertEqual(Set(first.rounds.map(\.opponentName)).count, 3)
        XCTAssertEqual(first.rounds[0].difficulty, .rookie)
        XCTAssertEqual(first.rounds[1].difficulty, .pro)
        XCTAssertEqual(first.rounds[2].difficulty, .champion)
        XCTAssertEqual(first.rounds[2].cupCount, .ten)
    }

    @MainActor
    func testWeeklyTournamentScoreUsesWinsAndTitle() {
        XCTAssertEqual(TournamentStore.shared.weeklyScore, TournamentStore.shared.winsThisWeek * 10 + (TournamentStore.shared.championThisWeek ? 50 : 0))
    }

    func testTournamentWinPaysTitleBonus() {
        var config = MatchConfiguration.quickMatch(
            difficulty: .champion,
            cupCount: .ten,
            aimAssistance: false,
            playerName: "Sam"
        )
        config.mode = .tournament
        config.eventRound = 3
        let rewards = RewardCalculator.breakdown(
            configuration: config,
            playerWon: true,
            playerMakes: 6,
            bestStreak: 2,
            alreadyGranted: false
        )
        XCTAssertEqual(rewards.coins, AIDifficulty.champion.winCoins + 25 + 75)
    }

    func testChallengeWinUsesChallengeCoins() {
        let config = ChallengeDefinition.clutchThree.configuration(playerName: "Sam", aimAssistance: false)
        XCTAssertEqual(config.mode, .challenge)
        XCTAssertTrue(config.isSuddenDeath)
        let rewards = RewardCalculator.breakdown(
            configuration: config,
            playerWon: true,
            playerMakes: 3,
            bestStreak: 3,
            alreadyGranted: false
        )
        XCTAssertEqual(rewards.coins, ChallengeDefinition.clutchThree.rewardCoins)
    }

    @MainActor
    func testTournamentStoreAdvancesAndEliminates() {
        let suite = "cupclash.tournament.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            return XCTFail("Could not create isolated defaults")
        }
        defaults.removePersistentDomain(forName: suite)
        let store = TournamentStore(defaults: defaults)
        let event = TournamentEvent.current()
        guard let opening = event.configuration(round: 1, playerName: "Sam", aimAssistance: false) else {
            return XCTFail("Missing opening match")
        }

        store.record(result: makeResult(configuration: opening, won: true, makes: 4))
        XCTAssertEqual(store.currentRound, 2)
        XCTAssertFalse(store.eliminated)

        guard let semi = event.configuration(round: 2, playerName: "Sam", aimAssistance: false) else {
            return XCTFail("Missing semifinal")
        }
        store.record(result: makeResult(configuration: semi, won: false, makes: 1))
        XCTAssertTrue(store.eliminated)
        XCTAssertEqual(store.titles, 0)

        store.retryWeek()
        XCTAssertFalse(store.eliminated)
        XCTAssertEqual(store.currentRound, 1)

        guard let final = event.configuration(round: 3, playerName: "Sam", aimAssistance: false) else {
            return XCTFail("Missing final")
        }
        store.record(result: makeResult(configuration: final, won: true, makes: 8))
        XCTAssertEqual(store.titles, 1)
        XCTAssertTrue(store.championThisWeek)
        XCTAssertEqual(store.currentRound, 4)
        defaults.removePersistentDomain(forName: suite)
    }

    @MainActor
    func testChallengeStoreCompletesObjectives() {
        let suite = "cupclash.challenges.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            return XCTFail("Could not create isolated defaults")
        }
        defaults.removePersistentDomain(forName: suite)
        let store = ChallengeStore(defaults: defaults)
        let clutch = ChallengeDefinition.clutchThree.configuration(playerName: "Sam", aimAssistance: false)
        let newly = store.record(result: makeResult(configuration: clutch, won: true, makes: 3, streak: 3, opponentMakes: 1))
        XCTAssertTrue(newly.contains(where: { $0.id == ChallengeDefinition.clutchThree.id }))
        XCTAssertTrue(store.isComplete(ChallengeDefinition.clutchThree.id))

        let perfect = ChallengeDefinition.perfectRack.configuration(playerName: "Sam", aimAssistance: true)
        let perfectResult = makeResult(configuration: perfect, won: true, makes: 6, shots: 6, streak: 6, opponentMakes: 0, perfect: true)
        store.record(result: perfectResult)
        XCTAssertTrue(store.isComplete(ChallengeDefinition.perfectRack.id))
        XCTAssertTrue(store.isComplete(ChallengeDefinition.cleanSheet.id))
        XCTAssertTrue(store.isComplete(ChallengeDefinition.hotStreak.id))
        defaults.removePersistentDomain(forName: suite)
    }

    func testFeaturedChallengesAreTwoDistinct() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 13))!
        let featured = ChallengeDefinition.featuredIDs(for: date, calendar: calendar)
        XCTAssertEqual(featured.count, 2)
        XCTAssertEqual(Set(featured).count, 2)
        XCTAssertFalse(featured.contains(ChallengeDefinition.daily.id))
    }

    private func makeResult(
        configuration: MatchConfiguration,
        won: Bool,
        makes: Int,
        shots: Int? = nil,
        streak: Int = 1,
        opponentMakes: Int = 0,
        perfect: Bool = false
    ) -> MatchResult {
        MatchResult(
            id: UUID(),
            configuration: configuration,
            winner: won ? .player : .opponent,
            playerWon: won,
            playerCupsRemaining: 3,
            opponentCupsRemaining: won ? 0 : 3,
            playerShots: shots ?? makes + 1,
            playerMakes: makes,
            opponentShots: opponentMakes + 1,
            opponentMakes: opponentMakes,
            bestStreak: streak,
            perfectGame: perfect,
            rewards: RewardBreakdown(matchXP: 25, winXP: won ? 75 : 0, cupXP: makes * 5, streakXP: 0, coins: 0, levelUpCoins: 0, levelsGained: 0, alreadyGranted: false),
            startingTotalXP: 0,
            endingTotalXP: 100,
            startingLevel: 1,
            endingLevel: 1
        )
    }
}
