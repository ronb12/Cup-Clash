import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case matchSetup(GameMode)
    case gameplay(MatchConfiguration)
    case results
    case practice
    case locker
    case profile
    case settings
    case howToPlay
    case leaderboards
    case achievements
    case tournaments
    case challenges
}

@MainActor
@Observable
final class AppRouter {
    var path = NavigationPath()
    var lastResult: MatchResult?

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func start(_ configuration: MatchConfiguration) {
        push(.gameplay(configuration))
    }

    /// Drops the results screen and the finished match, then starts a new game.
    func replaceGameplay(with configuration: MatchConfiguration) {
        let drop = min(path.count, 2)
        if drop > 0 {
            path.removeLast(drop)
        }
        start(configuration)
    }

    func rematch(_ configuration: MatchConfiguration) {
        var next = configuration
        next.seed = UInt64.random(in: 1...UInt64.max)
        replaceGameplay(with: next)
    }

    func showResults(_ result: MatchResult) {
        lastResult = result
        path.append(AppRoute.results)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToHome() {
        path = NavigationPath()
        lastResult = nil
    }
}
