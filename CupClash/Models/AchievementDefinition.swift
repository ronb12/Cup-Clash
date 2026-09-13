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
        AchievementDefinition(id: GameCenterIDs.threeInARow, title: "Three in a Row", detail: "Make three cups in a row.", symbolName: "flame.fill"),
        AchievementDefinition(id: GameCenterIDs.championDefeated, title: "Champion Defeated", detail: "Beat Champion difficulty.", symbolName: "crown.fill"),
        AchievementDefinition(id: GameCenterIDs.collector, title: "Collector", detail: "Unlock every ball and cup style.", symbolName: "square.grid.2x2.fill")
    ]
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
        }
    }
}
