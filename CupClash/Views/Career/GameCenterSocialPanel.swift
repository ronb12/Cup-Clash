import SwiftUI

struct GameCenterSocialPanel: View {
    var boardID: String
    var detail: String
    @State private var friends: [LeaderboardRow] = []
    @State private var inviteMessage = ""

    var body: some View {
        let manager = GameCenterManager.shared
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Game Center")
                Text(manager.isAuthenticated
                     ? "Signed in as \(manager.playerDisplayName). \(detail)"
                     : "Sign in to compete with friends on this board and send Game Center friend invites.")
                    .foregroundStyle(CupClashTheme.textSecondary)

                if !friends.isEmpty {
                    ForEach(friends.prefix(5)) { row in
                        HStack {
                            Text("\(row.rank)")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(CupClashTheme.gold)
                                .frame(width: 28, alignment: .leading)
                            Text(row.isLocalPlayer ? "You" : row.name)
                                .fontWeight(row.isLocalPlayer ? .bold : .regular)
                            Spacer()
                            Text("\(row.value)")
                                .monospacedDigit()
                                .foregroundStyle(row.isLocalPlayer ? CupClashTheme.cyan : CupClashTheme.textSecondary)
                        }
                        .accessibilityLabel("Rank \(row.rank), \(row.name), \(row.value)")
                    }
                }

                if !inviteMessage.isEmpty {
                    Text(inviteMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(CupClashTheme.warning)
                }

                if manager.isAuthenticated {
                    SecondaryButton(title: "Invite Friends", symbol: "person.crop.circle.badge.plus") {
                        manager.presentFriendInvite()
                        inviteMessage = manager.lastError ?? ""
                    }
                    SecondaryButton(title: "Friends List", symbol: "person.2.fill") {
                        manager.presentFriends()
                    }
                    SecondaryButton(title: "Friends Board", symbol: "list.star") {
                        manager.presentLeaderboard(id: boardID, friendsOnly: true)
                    }
                } else {
                    SecondaryButton(title: "Sign In to Game Center", symbol: "gamecontroller") {
                        manager.authenticate()
                    }
                }
            }
        }
        .task(id: boardID) {
            friends = await GameCenterManager.shared.loadEntries(for: boardID, friendsOnly: true)
        }
    }
}
