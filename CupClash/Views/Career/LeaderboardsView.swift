import SwiftUI

struct LeaderboardsView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings
    @State private var selected = LeaderboardDefinition.all[0]
    @State private var remote: [LeaderboardRow] = []
    @State private var loading = false
    @State private var friendsOnly = false

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            ScrollView {
                VStack(spacing: 16) {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Boards")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(LeaderboardDefinition.all) { board in
                                        Button(board.title) { selected = board }
                                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .foregroundStyle(selected.id == board.id ? CupClashTheme.navy : CupClashTheme.cyan)
                                            .background(
                                                Capsule().fill(selected.id == board.id ? AnyShapeStyle(CupClashTheme.neonGradient()) : AnyShapeStyle(Color.white.opacity(0.08)))
                                            )
                                    }
                                }
                            }
                            .mask(
                                HStack(spacing: 0) {
                                    Color.black
                                    LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                                        .frame(width: 28)
                                }
                            )
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selected.title)
                                .font(CupClashTheme.headlineFont)
                            Text(selected.detail)
                                .foregroundStyle(CupClashTheme.textSecondary)
                            HStack {
                                Text("Your best")
                                Spacer()
                                Text("\(localValue) \(selected.unit)")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundStyle(CupClashTheme.cyan)
                                    .monospacedDigit()
                            }
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: friendsOnly ? "Friends" : (GameCenterManager.shared.isAuthenticated ? "Game Center" : "Local"))
                            if GameCenterManager.shared.isAuthenticated {
                                Picker("Audience", selection: $friendsOnly) {
                                    Text("Global").tag(false)
                                    Text("Friends").tag(true)
                                }
                                .pickerStyle(.segmented)
                            }
                            if loading {
                                ProgressView()
                                    .tint(CupClashTheme.cyan)
                                    .frame(maxWidth: .infinity)
                            } else if rows.isEmpty {
                                Text(GameCenterManager.shared.isAuthenticated
                                     ? "No scores on this board yet."
                                     : "No score yet — play a match to post your first one. Sign in with Game Center in Settings for friends and global ranks.")
                                    .foregroundStyle(CupClashTheme.textSecondary)
                            } else {
                                ForEach(rows) { row in
                                    HStack {
                                        Text("\(row.rank)")
                                            .font(.system(.headline, design: .rounded).weight(.bold))
                                            .frame(width: 28, alignment: .leading)
                                            .foregroundStyle(CupClashTheme.gold)
                                        Text(row.name)
                                            .font(.system(.body, design: .rounded).weight(row.isLocalPlayer ? .bold : .regular))
                                        Spacer()
                                        Text("\(row.value)")
                                            .monospacedDigit()
                                            .foregroundStyle(row.isLocalPlayer ? CupClashTheme.cyan : CupClashTheme.textSecondary)
                                    }
                                    .accessibilityLabel("Rank \(row.rank), \(row.name), \(row.value) \(selected.unit)")
                                }
                            }
                        }
                    }

                    if GameCenterManager.shared.isAuthenticated {
                        SecondaryButton(title: "Invite Friends", symbol: "person.crop.circle.badge.plus") {
                            GameCenterManager.shared.presentFriendInvite()
                        }
                        SecondaryButton(title: "Open \(selected.title)", symbol: "gamecontroller") {
                            GameCenterManager.shared.presentLeaderboard(id: selected.id, friendsOnly: friendsOnly)
                        }
                    }

                    if !LocalScoreboard.shared.recentMatches().isEmpty {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeader(title: "Recent matches")
                                ForEach(LocalScoreboard.shared.recentMatches()) { match in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(match.modeTitle)
                                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                            Text("vs \(match.opponent)")
                                                .foregroundStyle(CupClashTheme.textSecondary)
                                        }
                                        Spacer()
                                        Text("\(match.playerMakes)–\(match.opponentMakes)")
                                            .monospacedDigit()
                                            .foregroundStyle(match.won ? CupClashTheme.neonGreen : CupClashTheme.warning)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Leaderboards")
        .task(id: "\(selected.id)-\(friendsOnly)") { await refresh() }
    }

    private var localValue: Int {
        if selected.id == GameCenterIDs.suddenDeathWins {
            return LocalScoreboard.shared.suddenDeathWins()
        }
        if selected.id == GameCenterIDs.dailyChallenge {
            return LocalScoreboard.shared.dailyBest()?.score
                ?? LocalScoreboard.shared.personalBest(for: selected.id)
        }
        if selected.id == GameCenterIDs.tournamentTitles {
            return max(LocalScoreboard.shared.personalBest(for: selected.id), TournamentStore.shared.titles)
        }
        if selected.id == GameCenterIDs.challengesCleared {
            return max(LocalScoreboard.shared.personalBest(for: selected.id), ChallengeStore.shared.completedCount)
        }
        if selected.id == GameCenterIDs.weeklyTournament {
            return max(LocalScoreboard.shared.personalBest(for: selected.id), TournamentStore.shared.weeklyScore)
        }
        let stored = LocalScoreboard.shared.personalBest(for: selected.id)
        if stored > 0 { return stored }
        switch selected.id {
        case GameCenterIDs.mostCareerWins: return profile.matchesWon
        case GameCenterIDs.mostCupsMade: return profile.shotsMade
        case GameCenterIDs.bestAccuracy: return Int(profile.accuracy.rounded())
        case GameCenterIDs.longestWinStreak: return profile.bestWinningStreak
        default: return 0
        }
    }

    private var rows: [LeaderboardRow] {
        if !remote.isEmpty { return remote }
        if localValue <= 0 { return [] }
        return [LeaderboardRow(rank: 1, name: profile.displayName, value: localValue, isLocalPlayer: true)]
    }

    private func refresh() async {
        loading = GameCenterManager.shared.isAuthenticated
        remote = await GameCenterManager.shared.loadEntries(for: selected.id, friendsOnly: friendsOnly)
        loading = false
    }
}
