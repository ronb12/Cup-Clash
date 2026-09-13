import GameKit
import SwiftUI

@MainActor
protocol GameCenterServicing: AnyObject {
    var isAuthenticated: Bool { get }
    var playerDisplayName: String { get }
    func authenticate()
    func presentDashboard()
    func submitScore(_ value: Int, leaderboardID: String)
    func reportAchievement(id: String, percent: Double)
    func sync(profile: PlayerProfile)
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
        guard isAuthenticated else { return }
        let controller = GKGameCenterViewController(state: .dashboard)
        controller.gameCenterDelegate = GameCenterPresenter.shared
        GameCenterPresenter.present(controller)
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
        let collectibleCount = BallStyle.catalog.count + CupStyle.catalog.count
        let unlockedCollectibles = profile.unlockedItemIDs.filter { id in
            BallStyle.catalog.contains(where: { $0.id == id }) || CupStyle.catalog.contains(where: { $0.id == id })
        }.count
        reportAchievement(id: GameCenterIDs.collector, percent: min(100, Double(unlockedCollectibles) / Double(collectibleCount) * 100))
    }
}

final class GameCenterPresenter: NSObject, GKGameCenterControllerDelegate, @unchecked Sendable {
    static let shared = GameCenterPresenter()

    @MainActor
    static func present(_ viewController: UIViewController) {
        guard let presenter = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController else { return }
        var top = presenter
        while let shown = top.presentedViewController {
            top = shown
        }
        top.present(viewController, animated: true)
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
