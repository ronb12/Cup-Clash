import Foundation

enum RewardCalculator {
    static func breakdown(
        configuration: MatchConfiguration,
        playerWon: Bool,
        playerMakes: Int,
        bestStreak: Int,
        alreadyGranted: Bool
    ) -> RewardBreakdown {
        if alreadyGranted || configuration.mode == .practice {
            return RewardBreakdown(
                matchXP: 0,
                winXP: 0,
                cupXP: 0,
                streakXP: 0,
                coins: 0,
                levelUpCoins: 0,
                levelsGained: 0,
                alreadyGranted: alreadyGranted
            )
        }

        let matchXP = configuration.mode == .practice ? 0 : AppConstants.matchCompleteXP
        let winXP = playerWon && configuration.mode != .practice ? AppConstants.matchWinXP : 0
        let cupXP = playerMakes * AppConstants.madeCupXP
        let streakXP = bestStreak >= AppConstants.streakBonusThreshold ? AppConstants.streakBonusXP : 0
        var coins = 0
        if configuration.mode.awardsCoins, !playerWon, configuration.mode != .challenge {
            // Consolation so a losing streak can still fund the locker.
            coins = min(AppConstants.consolationCoinCap, playerMakes * AppConstants.consolationCoinsPerCup)
        }
        if configuration.mode.awardsCoins, playerWon {
            if configuration.mode == .challenge {
                coins = ChallengeDefinition.rewardCoins(for: configuration.eventID)
            } else {
                coins = configuration.difficulty.winCoins
                if configuration.mode == .dailyChallenge {
                    coins += 40
                }
                if configuration.mode == .tournament {
                    coins += 25
                    if configuration.isFinalTournamentRound {
                        coins += 75
                    }
                }
                if configuration.isSuddenDeath {
                    coins += 15
                }
            }
        }

        return RewardBreakdown(
            matchXP: matchXP,
            winXP: winXP,
            cupXP: cupXP,
            streakXP: streakXP,
            coins: coins,
            levelUpCoins: 0,
            levelsGained: 0,
            alreadyGranted: false
        )
    }

    static func applyingLevelUps(to rewards: RewardBreakdown, startingTotalXP: Int) -> RewardBreakdown {
        let endingXP = startingTotalXP + rewards.totalXP
        let startLevel = ProgressionMath.level(forTotalXP: startingTotalXP)
        let endLevel = ProgressionMath.level(forTotalXP: endingXP)
        let gained = max(0, endLevel - startLevel)
        var copy = rewards
        copy.levelsGained = gained
        copy.levelUpCoins = gained * AppConstants.levelUpCoins
        return copy
    }
}

enum CosmeticStore {
    enum PurchaseResult: Equatable {
        case purchased
        case equipped
        case alreadyOwned
        case notEnoughCoins
        case unknownItem
    }

    static func purchase(
        itemID: String,
        price: Int,
        coins: Int,
        unlocked: [String]
    ) -> (result: PurchaseResult, coins: Int, unlocked: [String]) {
        if unlocked.contains(itemID) {
            return (.alreadyOwned, coins, unlocked)
        }
        guard price > 0 else {
            var owned = unlocked
            owned.append(itemID)
            return (.purchased, coins, owned)
        }
        guard coins >= price else {
            return (.notEnoughCoins, coins, unlocked)
        }
        var owned = unlocked
        owned.append(itemID)
        return (.purchased, coins - price, owned)
    }
}
