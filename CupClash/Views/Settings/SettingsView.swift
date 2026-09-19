import SwiftUI

struct SettingsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(GameSettings.self) private var settings
    @Environment(PlayerProfile.self) private var profile
    @State private var confirmReset = false

    var body: some View {
        @Bindable var settings = settings
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 16) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Audio & Feel")
                            Toggle("Music", isOn: $settings.musicEnabled)
                            Toggle("Sound effects", isOn: $settings.soundEffectsEnabled)
                            Toggle("Haptics", isOn: $settings.hapticsEnabled)
                        }
                        .tint(CupClashTheme.cyan)
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Gameplay")
                            Toggle("Trajectory guide", isOn: $settings.trajectoryGuideEnabled)
                            Toggle("Aim assistance", isOn: $settings.aimAssistanceEnabled)
                            Text("Slight pull toward a nearby cup. Leave off for a real challenge.")
                                .font(.footnote)
                                .foregroundStyle(CupClashTheme.textSecondary)
                            Toggle("Left-handed controls", isOn: $settings.leftHandedControls)
                            VStack(alignment: .leading) {
                                Text("Throw sensitivity")
                                Slider(value: $settings.throwSensitivity, in: 0.5...1.8, step: 0.1)
                            }
                            HStack {
                                Text("Default difficulty")
                                Spacer()
                                Picker("Default difficulty", selection: $settings.preferredDifficultyRaw) {
                                    ForEach(AIDifficulty.allCases) { level in
                                        Text(level.title).tag(level.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            HStack {
                                Text("Default cup count")
                                Spacer()
                                Picker("Default cup count", selection: $settings.preferredCupCountRaw) {
                                    ForEach(CupCount.allCases) { count in
                                        Text(count.title).tag(count.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .tint(CupClashTheme.cyan)
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Accessibility")
                            Toggle("Reduce motion", isOn: $settings.reducedMotion)
                            Toggle("High contrast", isOn: $settings.highContrast)
                            Text("Gameplay uses text plus icons, not color alone. Throw controls support slow drag and VoiceOver increment.")
                                .font(.footnote)
                                .foregroundStyle(CupClashTheme.textSecondary)
                        }
                        .tint(CupClashTheme.cyan)
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Game Center")
                            Text(GameCenterManager.shared.isAuthenticated
                                 ? "Signed in as \(GameCenterManager.shared.playerDisplayName)"
                                 : "Game Center is optional. The game works offline.")
                                .foregroundStyle(CupClashTheme.textSecondary)
                            SecondaryButton(title: "Leaderboards", symbol: "list.number") {
                                router.push(.leaderboards)
                            }
                            SecondaryButton(title: "Achievements", symbol: "rosette") {
                                router.push(.achievements)
                            }
                            if !GameCenterManager.shared.isAuthenticated {
                                SecondaryButton(title: "Sign In to Game Center", symbol: "person.crop.circle.badge.checkmark") {
                                    GameCenterManager.shared.authenticate()
                                }
                            }
                            SecondaryButton(title: "Invite Friends", symbol: "person.crop.circle.badge.plus") {
                                GameCenterManager.shared.presentFriendInvite()
                            }
                            SecondaryButton(title: "Friends", symbol: "person.2.fill") {
                                GameCenterManager.shared.presentFriends()
                            }
                            SecondaryButton(title: "Open Game Center", symbol: "gamecontroller") {
                                GameCenterManager.shared.presentDashboard()
                            }
                        }
                    }

                    SecondaryButton(title: "Reset Progress", symbol: "trash", destructive: true) {
                        confirmReset = true
                    }
                    CreatorCredit()
                }
                .padding(20)
                .font(.system(.body, design: .rounded))
            }
        }
        .navigationTitle("Settings")
        .onChange(of: settings.musicEnabled) { _, _ in persist() }
        .onChange(of: settings.soundEffectsEnabled) { _, _ in persist() }
        .onChange(of: settings.hapticsEnabled) { _, _ in persist() }
        .onChange(of: settings.trajectoryGuideEnabled) { _, _ in persist() }
        .onChange(of: settings.aimAssistanceEnabled) { _, _ in persist() }
        .onChange(of: settings.leftHandedControls) { _, _ in persist() }
        .onChange(of: settings.reducedMotion) { _, _ in persist() }
        .onChange(of: settings.highContrast) { _, _ in persist() }
        .onChange(of: settings.throwSensitivity) { _, _ in persist() }
        .onChange(of: settings.preferredDifficultyRaw) { _, _ in persist() }
        .onChange(of: settings.preferredCupCountRaw) { _, _ in persist() }
        .confirmationDialog("Reset all coins, XP, and unlocks?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) {
                PersistenceManager.shared.resetProgress()
                AudioManager.shared.play(.miss)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func persist() {
        PersistenceManager.shared.save()
        AudioManager.shared.apply(settings: settings)
        HapticManager.shared.apply(settings: settings)
    }
}
