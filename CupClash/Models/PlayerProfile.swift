import Foundation
import SwiftData

@Model
final class PlayerProfile {
    var displayName: String
    var currentLevel: Int
    var currentXP: Int
    var totalXP: Int
    var coinBalance: Int
    var matchesPlayed: Int
    var matchesWon: Int
    var matchesLost: Int
    var shotsAttempted: Int
    var shotsMade: Int
    var currentWinningStreak: Int
    var bestWinningStreak: Int
    var selectedBallStyleID: String
    var selectedCupStyleID: String
    var selectedArenaID: String
    var unlockedItemIDs: [String]
    var lastRewardMatchID: String

    init(
        displayName: String = "Player One",
        currentLevel: Int = 1,
        currentXP: Int = 0,
        totalXP: Int = 0,
        coinBalance: Int = 0,
        matchesPlayed: Int = 0,
        matchesWon: Int = 0,
        matchesLost: Int = 0,
        shotsAttempted: Int = 0,
        shotsMade: Int = 0,
        currentWinningStreak: Int = 0,
        bestWinningStreak: Int = 0,
        selectedBallStyleID: String = BallStyle.catalog[0].id,
        selectedCupStyleID: String = CupStyle.catalog[0].id,
        selectedArenaID: String = ArenaStyle.neonCourt.id,
        unlockedItemIDs: [String] = [BallStyle.catalog[0].id, CupStyle.catalog[0].id],
        lastRewardMatchID: String = ""
    ) {
        self.displayName = displayName
        self.currentLevel = currentLevel
        self.currentXP = currentXP
        self.totalXP = totalXP
        self.coinBalance = coinBalance
        self.matchesPlayed = matchesPlayed
        self.matchesWon = matchesWon
        self.matchesLost = matchesLost
        self.shotsAttempted = shotsAttempted
        self.shotsMade = shotsMade
        self.currentWinningStreak = currentWinningStreak
        self.bestWinningStreak = bestWinningStreak
        self.selectedBallStyleID = selectedBallStyleID
        self.selectedCupStyleID = selectedCupStyleID
        self.selectedArenaID = selectedArenaID
        self.unlockedItemIDs = unlockedItemIDs
        self.lastRewardMatchID = lastRewardMatchID
    }

    var accuracy: Double {
        AccuracyMath.percent(made: shotsMade, attempted: shotsAttempted)
    }

    func isUnlocked(_ id: String) -> Bool {
        unlockedItemIDs.contains(id)
    }
}
