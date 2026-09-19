import Foundation

struct AchievementDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String

    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: GameCenterIDs.firstCup, title: "First Cup", detail: "Land your first cup.", symbolName: "cup.and.saucer.fill"),
        AchievementDefinition(id: GameCenterIDs.firstVictory, title: "First Victory", detail: "Win a match.", symbolName: "trophy"),
        AchievementDefinition(id: GameCenterIDs.tenVictories, title: "Ten Victories", detail: "Win 10 matches.", symbolName: "10.circle.fill"),
        AchievementDefinition(id: GameCenterIDs.fiftyVictories, title: "Fifty Victories", detail: "Win 50 matches.", symbolName: "star.circle.fill"),
        AchievementDefinition(id: GameCenterIDs.perfectMatch, title: "Perfect Match", detail: "Clear every cup without a miss.", symbolName: "sparkles"),
        AchievementDefinition(id: GameCenterIDs.threeInARow, title: "Three in a Row", detail: "Win three matches in a row.", symbolName: "flame.fill"),
        AchievementDefinition(id: GameCenterIDs.championDefeated, title: "Champion Defeated", detail: "Beat Champion difficulty.", symbolName: "crown.fill"),
        AchievementDefinition(id: GameCenterIDs.collector, title: "Collector", detail: "Unlock every ball, cup, and arena.", symbolName: "square.grid.2x2.fill"),
        AchievementDefinition(id: GameCenterIDs.dailyChallenger, title: "Daily Challenger", detail: "Win today's Daily Challenge.", symbolName: "calendar.badge.checkmark"),
        AchievementDefinition(id: GameCenterIDs.clutchFinish, title: "Clutch Finish", detail: "Win a Sudden Death match.", symbolName: "bolt.heart.fill"),
        AchievementDefinition(id: GameCenterIDs.tournamentChampion, title: "Cup Champion", detail: "Win a weekly tournament.", symbolName: "trophy.fill"),
        AchievementDefinition(id: GameCenterIDs.challengeHunter, title: "Challenge Hunter", detail: "Complete 4 challenges.", symbolName: "flag.checkered")
    ]
}

@MainActor
enum AchievementProgress {
    static func percent(for achievement: AchievementDefinition, profile: PlayerProfile, scoreboard: LocalScoreboard) -> Double {
        switch achievement.id {
        case GameCenterIDs.firstCup:
            return profile.shotsMade >= 1 ? 100 : 0
        case GameCenterIDs.firstVictory:
            return profile.matchesWon >= 1 ? 100 : 0
        case GameCenterIDs.tenVictories:
            return min(100, Double(profile.matchesWon) / 10 * 100)
        case GameCenterIDs.fiftyVictories:
            return min(100, Double(profile.matchesWon) / 50 * 100)
        case GameCenterIDs.perfectMatch:
            return scoreboard.recentMatches().contains(where: { $0.won && $0.playerMakes > 0 && $0.opponentMakes == 0 }) ? 100 : 0
        case GameCenterIDs.threeInARow:
            return min(100, Double(profile.bestWinningStreak) / 3 * 100)
        case GameCenterIDs.championDefeated:
            return scoreboard.recentMatches().contains(where: { $0.won && $0.opponent.contains("Champion") }) ? 100 : 0
        case GameCenterIDs.collector:
            let catalog = BallStyle.catalog.count + CupStyle.catalog.count + ArenaStyle.catalog.count
            let unlocked = profile.unlockedItemIDs.filter { id in
                BallStyle.catalog.contains(where: { $0.id == id })
                    || CupStyle.catalog.contains(where: { $0.id == id })
                    || ArenaStyle.catalog.contains(where: { $0.id == id })
            }.count
            return catalog == 0 ? 0 : min(100, Double(unlocked) / Double(catalog) * 100)
        case GameCenterIDs.dailyChallenger:
            let today = DailyChallenge.dayID()
            return scoreboard.recentMatches().contains(where: { $0.won && $0.modeTitle == GameMode.dailyChallenge.title && DailyChallenge.dayID(for: $0.date) == today }) ? 100 : 0
        case GameCenterIDs.clutchFinish:
            return scoreboard.suddenDeathWins() >= 1 ? 100 : 0
        case GameCenterIDs.tournamentChampion:
            return TournamentStore.shared.titles >= 1 ? 100 : 0
        case GameCenterIDs.challengeHunter:
            return min(100, Double(ChallengeStore.shared.completedCount) / 4 * 100)
        default:
            return 0
        }
    }

    static func isComplete(for achievement: AchievementDefinition, profile: PlayerProfile, scoreboard: LocalScoreboard) -> Bool {
        percent(for: achievement, profile: profile, scoreboard: scoreboard) >= 100
    }
}

enum GameCenterAchievement: String, CaseIterable, Sendable {
    case firstCup
    case firstVictory
    case tenVictories
    case fiftyVictories
    case perfectMatch
    case threeInARow
    case championDefeated
    case collector
    case dailyChallenger
    case clutchFinish
    case tournamentChampion
    case challengeHunter

    var identifier: String {
        switch self {
        case .firstCup: GameCenterIDs.firstCup
        case .firstVictory: GameCenterIDs.firstVictory
        case .tenVictories: GameCenterIDs.tenVictories
        case .fiftyVictories: GameCenterIDs.fiftyVictories
        case .perfectMatch: GameCenterIDs.perfectMatch
        case .threeInARow: GameCenterIDs.threeInARow
        case .championDefeated: GameCenterIDs.championDefeated
        case .collector: GameCenterIDs.collector
        case .dailyChallenger: GameCenterIDs.dailyChallenger
        case .clutchFinish: GameCenterIDs.clutchFinish
        case .tournamentChampion: GameCenterIDs.tournamentChampion
        case .challengeHunter: GameCenterIDs.challengeHunter
        }
    }
}
