import GameKit
import SwiftUI

@MainActor
protocol GameCenterServicing: AnyObject {
    var isAuthenticated: Bool { get }
    var playerDisplayName: String { get }
    func authenticate()
    func presentDashboard()
    func presentLeaderboard(id: String, friendsOnly: Bool)
    func presentAchievements()
    func presentFriends()
    func presentFriendInvite()
    func submitScore(_ value: Int, leaderboardID: String)
    func reportAchievement(id: String, percent: Double)
    func sync(profile: PlayerProfile)
    func loadEntries(for leaderboardID: String, friendsOnly: Bool) async -> [LeaderboardRow]
    func loadFriendNames() async -> [String]
}

@MainActor
@Observable
final class GameCenterManager: NSObject, GameCenterServicing {
    static let shared = GameCenterManager()

    private(set) var isAuthenticated = false
    private(set) var lastError: String?

    var playerDisplayName: String {
        isAuthenticated ? GKLocalPlayer.local.displayName : "Offline"
    }

    func authenticate() {
        guard !ProcessInfo.processInfo.arguments.contains("--uitesting") else { return }
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    GameCenterPresenter.present(viewController)
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if let error {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func presentDashboard() {
        presentGameCenter(state: .dashboard)
    }

    func presentLeaderboard(id: String, friendsOnly: Bool = false) {
        guard isAuthenticated else { return }
        let scope: GKLeaderboard.PlayerScope = friendsOnly ? .friendsOnly : .global
        let time: GKLeaderboard.TimeScope = id == GameCenterIDs.weeklyTournament ? .week : .allTime
        let controller = GKGameCenterViewController(leaderboardID: id, playerScope: scope, timeScope: time)
        controller.gameCenterDelegate = GameCenterPresenter.shared
        GameCenterPresenter.present(controller)
    }

    func presentAchievements() {
        presentGameCenter(state: .achievements)
    }

    func presentFriends() {
        presentGameCenter(state: .localPlayerFriendsList)
    }

    func presentFriendInvite() {
        guard isAuthenticated else {
            lastError = "Sign in to Game Center to invite friends."
            authenticate()
            return
        }
        guard let host = GameCenterPresenter.hostController() else {
            lastError = "Could not open the friend invite sheet."
            return
        }
        do {
            try GKLocalPlayer.local.presentFriendRequestCreator(from: host)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func presentGameCenter(state: GKGameCenterViewControllerState) {
        guard isAuthenticated else { return }
        let controller = GKGameCenterViewController(state: state)
        controller.gameCenterDelegate = GameCenterPresenter.shared
        GameCenterPresenter.present(controller)
    }

    func loadEntries(for leaderboardID: String, friendsOnly: Bool = false) async -> [LeaderboardRow] {
        guard isAuthenticated else { return [] }
        do {
            let boards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            guard let board = boards.first else { return [] }
            let scope: GKLeaderboard.PlayerScope = friendsOnly ? .friendsOnly : .global
            let time: GKLeaderboard.TimeScope = leaderboardID == GameCenterIDs.weeklyTournament ? .week : .allTime
            let (_, entries, _) = try await board.loadEntries(for: scope, timeScope: time, range: NSRange(location: 1, length: 25))
            return entries.enumerated().map { index, entry in
                LeaderboardRow(
                    rank: entry.rank > 0 ? entry.rank : index + 1,
                    name: entry.player.displayName,
                    value: Int(entry.score),
                    isLocalPlayer: entry.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID
                )
            }
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    func loadFriendNames() async -> [String] {
        guard isAuthenticated else { return [] }
        do {
            let status = try await GKLocalPlayer.local.loadFriendsAuthorizationStatus()
            guard status == .authorized || status == .notDetermined else { return [] }
            let friends = try await GKLocalPlayer.local.loadFriends()
            return friends.map(\.displayName)
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    func submitScore(_ value: Int, leaderboardID: String) {
        guard isAuthenticated, value >= 0, !leaderboardID.isEmpty else { return }
        GKLeaderboard.submitScore(
            value,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { _ in }
    }

    func reportAchievement(id: String, percent: Double) {
        guard isAuthenticated, !id.isEmpty else { return }
        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = min(100, max(0, percent))
        achievement.showsCompletionBanner = percent >= 100
        GKAchievement.report([achievement], withCompletionHandler: { _ in })
    }

    func sync(profile: PlayerProfile) {
        submitScore(profile.matchesWon, leaderboardID: GameCenterIDs.mostCareerWins)
        submitScore(Int(profile.accuracy.rounded()), leaderboardID: GameCenterIDs.bestAccuracy)
        submitScore(profile.bestWinningStreak, leaderboardID: GameCenterIDs.longestWinStreak)
        submitScore(profile.shotsMade, leaderboardID: GameCenterIDs.mostCupsMade)
        submitScore(LocalScoreboard.shared.personalBest(for: GameCenterIDs.dailyChallenge), leaderboardID: GameCenterIDs.dailyChallenge)
        submitScore(LocalScoreboard.shared.suddenDeathWins(), leaderboardID: GameCenterIDs.suddenDeathWins)
        submitScore(TournamentStore.shared.titles, leaderboardID: GameCenterIDs.tournamentTitles)
        submitScore(ChallengeStore.shared.completedCount, leaderboardID: GameCenterIDs.challengesCleared)
        submitScore(TournamentStore.shared.weeklyScore, leaderboardID: GameCenterIDs.weeklyTournament)

        if profile.shotsMade >= 1 {
            reportAchievement(id: GameCenterIDs.firstCup, percent: 100)
        }
        if profile.matchesWon >= 1 {
            reportAchievement(id: GameCenterIDs.firstVictory, percent: 100)
        }
        reportAchievement(id: GameCenterIDs.tenVictories, percent: min(100, Double(profile.matchesWon) / 10 * 100))
        reportAchievement(id: GameCenterIDs.fiftyVictories, percent: min(100, Double(profile.matchesWon) / 50 * 100))
        if profile.bestWinningStreak >= 3 {
            reportAchievement(id: GameCenterIDs.threeInARow, percent: 100)
        }
        let collectibleCount = BallStyle.catalog.count + CupStyle.catalog.count + ArenaStyle.catalog.count
        let unlockedCollectibles = profile.unlockedItemIDs.filter { id in
            BallStyle.catalog.contains(where: { $0.id == id })
                || CupStyle.catalog.contains(where: { $0.id == id })
                || ArenaStyle.catalog.contains(where: { $0.id == id })
        }.count
        reportAchievement(id: GameCenterIDs.collector, percent: min(100, Double(unlockedCollectibles) / Double(collectibleCount) * 100))
        if LocalScoreboard.shared.suddenDeathWins() >= 1 {
            reportAchievement(id: GameCenterIDs.clutchFinish, percent: 100)
        }
        if let daily = LocalScoreboard.shared.dailyBest(), daily.day == DailyChallenge.dayID(), daily.score >= 50 {
            reportAchievement(id: GameCenterIDs.dailyChallenger, percent: 100)
        }
        if TournamentStore.shared.titles >= 1 {
            reportAchievement(id: GameCenterIDs.tournamentChampion, percent: 100)
        }
        reportAchievement(
            id: GameCenterIDs.challengeHunter,
            percent: min(100, Double(ChallengeStore.shared.completedCount) / 4 * 100)
        )
    }
}

final class GameCenterPresenter: NSObject, GKGameCenterControllerDelegate, @unchecked Sendable {
    static let shared = GameCenterPresenter()

    @MainActor
    static func hostController() -> UIViewController? {
        guard let presenter = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController else { return nil }
        var top = presenter
        while let shown = top.presentedViewController {
            top = shown
        }
        return top
    }

    @MainActor
    static func present(_ viewController: UIViewController) {
        hostController()?.present(viewController, animated: true)
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
}

/// Placeholder for future real-time matches. Intentionally non-functional.
@MainActor
final class FutureOnlineMatchService: OnlineMatchServicing {
    static let shared = FutureOnlineMatchService()
    private(set) var isConnected = false

    func hostMatch(configuration: MatchConfiguration) async throws {
        throw OnlineMatchUnavailable()
    }

    func joinMatch(inviteID: String) async throws {
        throw OnlineMatchUnavailable()
    }

    func send(_ message: OnlineMatchMessage) {}
    func disconnect() { isConnected = false }
}

struct OnlineMatchUnavailable: LocalizedError {
    var errorDescription: String? {
        "Online multiplayer is prepared but not enabled in this version."
    }
}
