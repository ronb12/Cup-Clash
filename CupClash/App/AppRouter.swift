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
