import Foundation

@MainActor
final class LocalScoreboard {
    static let shared = LocalScoreboard()

    private let defaults: UserDefaults
    private let bestPrefix = "cupclash.best."
    private let dailyKey = "cupclash.daily.best"
    private let suddenKey = "cupclash.sudden.wins"
    private let historyKey = "cupclash.match.history"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func personalBest(for leaderboardID: String) -> Int {
        defaults.integer(forKey: bestPrefix + leaderboardID)
    }

    func suddenDeathWins() -> Int {
        defaults.integer(forKey: suddenKey)
    }

    func dailyBest() -> (day: String, score: Int)? {
        guard let data = defaults.data(forKey: dailyKey),
              let stored = try? JSONDecoder().decode(DailyBest.self, from: data) else { return nil }
        return (stored.day, stored.score)
    }

    func recentMatches() -> [LocalMatchRecord] {
        guard let data = defaults.data(forKey: historyKey),
              let records = try? JSONDecoder().decode([LocalMatchRecord].self, from: data) else { return [] }
        return records
    }

    func record(result: MatchResult, playerName: String, profile: PlayerProfile) {
        writeBest(GameCenterIDs.mostCareerWins, profile.matchesWon)
        writeBest(GameCenterIDs.mostCupsMade, profile.shotsMade)
        writeBest(GameCenterIDs.bestAccuracy, Int(profile.accuracy.rounded()))
        writeBest(GameCenterIDs.longestWinStreak, profile.bestWinningStreak)

        if result.configuration.mode == .dailyChallenge {
            let score = DailyChallenge.score(makes: result.playerMakes, won: result.playerWon)
            let day = DailyChallenge.dayID()
            let previous = dailyBest()
            if previous?.day != day || score > (previous?.score ?? 0) {
                if let data = try? JSONEncoder().encode(DailyBest(day: day, score: score)) {
                    defaults.set(data, forKey: dailyKey)
                }
                writeBest(GameCenterIDs.dailyChallenge, max(score, personalBest(for: GameCenterIDs.dailyChallenge)))
            }
        }

        if result.playerWon && result.configuration.isSuddenDeath {
            let wins = suddenDeathWins() + 1
            defaults.set(wins, forKey: suddenKey)
            writeBest(GameCenterIDs.suddenDeathWins, wins)
        }

        writeBest(GameCenterIDs.tournamentTitles, TournamentStore.shared.titles)
        writeBest(GameCenterIDs.challengesCleared, ChallengeStore.shared.completedCount)
        writeBest(GameCenterIDs.weeklyTournament, TournamentStore.shared.weeklyScore)

        var history = recentMatches()
        let modeTitle: String = {
            if !result.configuration.eventTitle.isEmpty { return result.configuration.eventTitle }
            if result.configuration.isSuddenDeath { return "Sudden Death" }
            return result.configuration.mode.title
        }()
        history.insert(
            LocalMatchRecord(
                id: result.id.uuidString,
                date: Date(),
                modeTitle: modeTitle,
                opponent: result.configuration.opponentName,
                playerName: playerName,
                playerMakes: result.playerMakes,
                opponentMakes: result.opponentMakes,
                won: result.playerWon
            ),
            at: 0
        )
        if history.count > 20 { history = Array(history.prefix(20)) }
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: historyKey)
        }
    }

    func reset() {
        for board in LeaderboardDefinition.all {
            defaults.removeObject(forKey: bestPrefix + board.id)
        }
        defaults.removeObject(forKey: dailyKey)
        defaults.removeObject(forKey: suddenKey)
        defaults.removeObject(forKey: historyKey)
    }

    private func writeBest(_ id: String, _ value: Int) {
        defaults.set(max(value, personalBest(for: id)), forKey: bestPrefix + id)
    }
}

struct DailyBest: Codable, Hashable, Sendable {
    var day: String
    var score: Int
}

struct LocalMatchRecord: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var date: Date
    var modeTitle: String
    var opponent: String
    var playerName: String
    var playerMakes: Int
    var opponentMakes: Int
    var won: Bool
}
