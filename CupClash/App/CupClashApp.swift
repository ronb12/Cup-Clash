import SwiftData
import SwiftUI

@main
struct CupClashApp: App {
    @State private var router = AppRouter()
    private let persistence = PersistenceManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(persistence.profile())
                .environment(persistence.settings())
                .onAppear {
                    bootstrap()
                }
        }
    }

    private func bootstrap() {
        let settings = persistence.settings()
        AudioManager.shared.apply(settings: settings)
        HapticManager.shared.apply(settings: settings)
        GameCenterManager.shared.authenticate()
        GameCenterManager.shared.sync(profile: persistence.profile())
    }
}
