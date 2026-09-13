import SwiftUI

struct ProfileView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings
    @State private var name: String = ""

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 16) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Display name")
                                .font(.system(.headline, design: .rounded))
                            TextField("Player name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { saveName() }
                            LevelProgressView(totalXP: profile.totalXP)
                            CoinBadge(amount: profile.coinBalance)
                        }
                    }
                    GlassPanel {
                        StatisticsView(profile: profile)
                    }
                    SecondaryButton(title: "Save Name", symbol: "checkmark") {
                        saveName()
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Profile")
        .onAppear { name = profile.displayName }
    }

    private func saveName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.displayName = trimmed.isEmpty ? "Player One" : String(trimmed.prefix(18))
        PersistenceManager.shared.save()
        AudioManager.shared.play(.button)
    }
}
