import Foundation
import simd

enum AppConstants {
    static let displayName = "Cup Clash"
    static let subtitle = "Pong Rivals"
    static let bundlePrefix = "com.bradleyvirtualsolutions.cupclash"

    static let matchCompleteXP = 25
    static let matchWinXP = 75
    static let madeCupXP = 5
    static let consolationCoinsPerCup = 3
    static let consolationCoinCap = 20
    static let streakBonusXP = 15
    static let streakBonusThreshold = 3
    static let levelUpCoins = 50
    static let baseLevelXP = 250
    static let extraLevelXP = 50

    static let rookieWinCoins = 20
    static let proWinCoins = 35
    static let championWinCoins = 50
}

enum ArenaMetrics {
    static let tableLength: Float = 2.44
    static let tableWidth: Float = 0.70
    static let tableThickness: Float = 0.05
    static let tableSurfaceY: Float = 0.78
    static let tableHalfLength: Float = tableLength / 2
    static let tableHalfWidth: Float = tableWidth / 2

    static let cupHeight: Float = 0.118
    static let cupTopRadius: Float = 0.046
    static let cupBottomRadius: Float = 0.029
    static let cupSpacing: Float = 0.098
    static let cupInset: Float = 0.18

    static let ballRadius: Float = 0.024
    static let throwOriginY: Float = tableSurfaceY + 0.10
    static let throwStandOff: Float = 0.42

    static let gravity = SIMD3<Float>(0, -9.81, 0)
}

enum GameCenterIDs {
    static let leaderboardPrefix = "\(AppConstants.bundlePrefix).leaderboard"
    static let achievementPrefix = "\(AppConstants.bundlePrefix).achievement"

    static let mostCareerWins = "\(leaderboardPrefix).most_career_wins"
    static let bestAccuracy = "\(leaderboardPrefix).best_accuracy"
    static let longestWinStreak = "\(leaderboardPrefix).longest_win_streak"
    static let mostCupsMade = "\(leaderboardPrefix).most_cups_made"
    static let dailyChallenge = "\(leaderboardPrefix).daily_challenge"
    static let suddenDeathWins = "\(leaderboardPrefix).sudden_death_wins"
    static let tournamentTitles = "\(leaderboardPrefix).tournament_titles"
    static let challengesCleared = "\(leaderboardPrefix).challenges_cleared"
    static let weeklyTournament = "\(leaderboardPrefix).weekly_tournament"

    static let firstCup = "\(achievementPrefix).first_cup"
    static let firstVictory = "\(achievementPrefix).first_victory"
    static let tenVictories = "\(achievementPrefix).ten_victories"
    static let fiftyVictories = "\(achievementPrefix).fifty_victories"
    static let perfectMatch = "\(achievementPrefix).perfect_match"
    static let threeInARow = "\(achievementPrefix).three_in_a_row"
    static let championDefeated = "\(achievementPrefix).champion_defeated"
    static let collector = "\(achievementPrefix).collector"
    static let dailyChallenger = "\(achievementPrefix).daily_challenger"
    static let clutchFinish = "\(achievementPrefix).clutch_finish"
    static let tournamentChampion = "\(achievementPrefix).tournament_champion"
    static let challengeHunter = "\(achievementPrefix).challenge_hunter"
}
