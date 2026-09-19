import Foundation

struct LeaderboardDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let unit: String

    static let all: [LeaderboardDefinition] = [
        LeaderboardDefinition(
            id: GameCenterIDs.mostCareerWins,
            title: "Career Wins",
            detail: "Ranked match wins across every mode",
            symbolName: "trophy.fill",
            unit: "wins"
        ),
        LeaderboardDefinition(
            id: GameCenterIDs.mostCupsMade,
            title: "Cups Made",
            detail: "Lifetime cups sunk",
            symbolName: "cup.and.saucer.fill",
            unit: "cups"
        ),
        LeaderboardDefinition(
            id: GameCenterIDs.bestAccuracy,
            title: "Accuracy",
            detail: "Lifetime make percentage",
            symbolName: "percent",
            unit: "%"
        ),
        LeaderboardDefinition(
            id: GameCenterIDs.longestWinStreak,
            title: "Win Streak",
            detail: "Best consecutive match wins",
            symbolName: "flame.fill",
            unit: "wins"
        ),
        LeaderboardDefinition(
            id: GameCenterIDs.dailyChallenge,
            title: "Daily Challenge",
            detail: "Best daily score (makes × 10, +50 for a win)",
            symbolName: "calendar",
            unit: "pts"
        ),
        LeaderboardDefinition(
            id: GameCenterIDs.suddenDeathWins,
            title: "Sudden Death",
            detail: "First-to-three wins",
            symbolName: "bolt.heart.fill",
            unit: "wins"
        ),
        LeaderboardDefinition(
            id: GameCenterIDs.tournamentTitles,
            title: "Tournament Titles",
            detail: "Weekly cups won",
            symbolName: "trophy.fill",
            unit: "titles"
        ),
        LeaderboardDefinition(
            id: GameCenterIDs.challengesCleared,
            title: "Challenges",
            detail: "Objectives completed",
            symbolName: "flag.checkered",
            unit: "cleared"
        ),
        LeaderboardDefinition(
            id: GameCenterIDs.weeklyTournament,
            title: "Weekly Cup",
            detail: "This week's tournament score (wins × 10, +50 for the title)",
            symbolName: "calendar.badge.trophy",
            unit: "pts"
        )
    ]
}

struct LeaderboardRow: Identifiable, Hashable, Sendable {
    var id: String { "\(rank)-\(name)-\(value)" }
    var rank: Int
    var name: String
    var value: Int
    var isLocalPlayer: Bool
}
