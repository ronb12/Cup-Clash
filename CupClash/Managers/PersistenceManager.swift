import Foundation
import SwiftData

@MainActor
final class PersistenceManager {
    static let shared = PersistenceManager()

    let container: ModelContainer?
    let context: ModelContext?
    let loadError: String?
    private var memoryProfile: PlayerProfile?
    private var memorySettings: GameSettings?

    private init() {
        let schema = Schema([PlayerProfile.self, GameSettings.self])
        do {
            let container = try ModelContainer(for: schema)
            self.container = container
            self.context = ModelContext(container)
            self.loadError = nil
            bootstrapIfNeeded()
        } catch {
            self.container = nil
            self.context = nil
            self.loadError = error.localizedDescription
            self.memoryProfile = PlayerProfile()
            self.memorySettings = GameSettings()
        }
    }

    func profile() -> PlayerProfile {
        if let memoryProfile { return memoryProfile }
        if let existing = fetchProfile() {
            return existing
        }
        let created = PlayerProfile()
        context?.insert(created)
        save()
        return created
    }

    func settings() -> GameSettings {
        if let memorySettings { return memorySettings }
        if let existing = fetchSettings() {
            return existing
        }
        let created = GameSettings()
        context?.insert(created)
        save()
        return created
    }

    func save() {
        guard let context else { return }
        do {
            try context.save()
        } catch {
            // Persistence failure must never crash gameplay.
        }
    }

    func resetProgress() {
        let current = profile()
        current.displayName = "Player One"
        current.currentLevel = 1
        current.currentXP = 0
        current.totalXP = 0
        current.coinBalance = 0
        current.matchesPlayed = 0
        current.matchesWon = 0
        current.matchesLost = 0
        current.shotsAttempted = 0
        current.shotsMade = 0
        current.currentWinningStreak = 0
        current.bestWinningStreak = 0
        current.selectedBallStyleID = BallStyle.catalog[0].id
        current.selectedCupStyleID = CupStyle.catalog[0].id
        current.selectedArenaID = ArenaStyle.neonCourt.id
        current.unlockedItemIDs = [BallStyle.catalog[0].id, CupStyle.catalog[0].id]
        current.lastRewardMatchID = ""
        save()
    }

    func apply(result: MatchResult) {
        let profile = profile()
        guard profile.lastRewardMatchID != result.id.uuidString else { return }

        if result.configuration.mode != .practice {
            profile.matchesPlayed += 1
            if result.playerWon {
                profile.matchesWon += 1
                profile.currentWinningStreak += 1
                profile.bestWinningStreak = max(profile.bestWinningStreak, profile.currentWinningStreak)
            } else if result.winner != nil {
                profile.matchesLost += 1
                profile.currentWinningStreak = 0
            }
        }

        profile.shotsAttempted += result.playerShots
        profile.shotsMade += result.playerMakes
        profile.totalXP += result.rewards.totalXP
        let progress = ProgressionMath.progress(totalXP: profile.totalXP)
        profile.currentLevel = progress.level
        profile.currentXP = progress.intoLevel
        profile.coinBalance += result.rewards.totalCoins
        profile.lastRewardMatchID = result.id.uuidString
        save()
    }

    func applyPurchase(itemID: String, remainingCoins: Int, unlocked: [String], selectedBall: String?, selectedCup: String?) {
        let profile = profile()
        profile.coinBalance = remainingCoins
        profile.unlockedItemIDs = unlocked
        if let selectedBall {
            profile.selectedBallStyleID = selectedBall
        }
        if let selectedCup {
            profile.selectedCupStyleID = selectedCup
        }
        save()
    }

    private func bootstrapIfNeeded() {
        _ = profile()
        _ = settings()
    }

    private func fetchProfile() -> PlayerProfile? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<PlayerProfile>()
        return try? context.fetch(descriptor).first
    }

    private func fetchSettings() -> GameSettings? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<GameSettings>()
        return try? context.fetch(descriptor).first
    }
}
