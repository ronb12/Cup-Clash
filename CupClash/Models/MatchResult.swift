import Foundation

struct RewardBreakdown: Equatable, Codable, Sendable {
    var matchXP: Int
    var winXP: Int
    var cupXP: Int
    var streakXP: Int
    var coins: Int
    var levelUpCoins: Int
    var levelsGained: Int
    var alreadyGranted: Bool

    var totalXP: Int { matchXP + winXP + cupXP + streakXP }
    var totalCoins: Int { coins + levelUpCoins }
}

struct MatchResult: Identifiable, Equatable, Codable, Sendable {
    var id: UUID
    var configuration: MatchConfiguration
    var winner: PlayerSide?
    var playerWon: Bool
    var playerCupsRemaining: Int
    var opponentCupsRemaining: Int
    var playerShots: Int
    var playerMakes: Int
    var opponentShots: Int
    var opponentMakes: Int
    var bestStreak: Int
    var perfectGame: Bool
    var rewards: RewardBreakdown
    var startingTotalXP: Int
    var endingTotalXP: Int
    var startingLevel: Int
    var endingLevel: Int

    var accuracy: Double {
        AccuracyMath.percent(made: playerMakes, attempted: playerShots)
    }
}
