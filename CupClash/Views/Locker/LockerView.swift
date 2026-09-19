import SwiftUI

struct LockerView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(GameSettings.self) private var settings
    @State private var tab = 0
    @State private var message = ""

    var body: some View {
        ZStack {
            ScreenBackground(highContrast: settings.highContrast)
            VStack(spacing: 16) {
                CoinBadge(amount: profile.coinBalance)
                Picker("Category", selection: $tab) {
                    Text("Balls").tag(0)
                    Text("Cups").tag(1)
                    Text("Arenas").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if !message.isEmpty {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(CupClashTheme.warning)
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if tab == 0 {
                            ForEach(BallStyle.catalog) { style in
                                BallStyleCard(
                                    style: style,
                                    unlocked: profile.isUnlocked(style.id),
                                    selected: profile.selectedBallStyleID == style.id,
                                    coins: profile.coinBalance,
                                    onBuy: { buy(id: style.id, price: style.price, kind: .ball) },
                                    onEquip: { equip(ballID: style.id) }
                                )
                            }
                        } else if tab == 1 {
                            ForEach(CupStyle.catalog) { style in
                                CupStyleCard(
                                    style: style,
                                    unlocked: profile.isUnlocked(style.id),
                                    selected: profile.selectedCupStyleID == style.id,
                                    coins: profile.coinBalance,
                                    onBuy: { buy(id: style.id, price: style.price, kind: .cup) },
                                    onEquip: { equip(cupID: style.id) }
                                )
                            }
                        } else {
                            ForEach(ArenaStyle.catalog) { style in
                                ArenaStyleCard(
                                    style: style,
                                    unlocked: profile.isUnlocked(style.id) || style.price == 0,
                                    selected: profile.selectedArenaID == style.id,
                                    coins: profile.coinBalance,
                                    onBuy: { buy(id: style.id, price: style.price, kind: .arena) },
                                    onEquip: { equip(arenaID: style.id) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 12)
        }
        .navigationTitle("Locker")
        .onAppear { unlockDefaultArena() }
    }

    private enum ItemKind { case ball, cup, arena }

    private func unlockDefaultArena() {
        if !profile.isUnlocked(ArenaStyle.neonCourt.id) {
            profile.unlockedItemIDs.append(ArenaStyle.neonCourt.id)
            PersistenceManager.shared.save()
        }
    }

    private func buy(id: String, price: Int, kind: ItemKind) {
        let outcome = CosmeticStore.purchase(
            itemID: id,
            price: price,
            coins: profile.coinBalance,
            unlocked: profile.unlockedItemIDs
        )
        switch outcome.result {
        case .purchased:
            PersistenceManager.shared.applyPurchase(
                itemID: id,
                remainingCoins: outcome.coins,
                unlocked: outcome.unlocked,
                selectedBall: kind == .ball ? id : nil,
                selectedCup: kind == .cup ? id : nil,
                selectedArena: kind == .arena ? id : nil
            )
            message = ""
            AudioManager.shared.play(.coins)
            HapticManager.shared.coins()
            GameCenterManager.shared.sync(profile: profile)
        case .notEnoughCoins:
            message = "Not enough coins yet."
        case .alreadyOwned:
            message = "Already unlocked."
        case .unknownItem, .equipped:
            message = ""
        }
    }

    private func equip(ballID: String? = nil, cupID: String? = nil, arenaID: String? = nil) {
        if let ballID, profile.isUnlocked(ballID) {
            profile.selectedBallStyleID = ballID
        }
        if let cupID, profile.isUnlocked(cupID) {
            profile.selectedCupStyleID = cupID
        }
        if let arenaID, profile.isUnlocked(arenaID) || ArenaStyle.style(id: arenaID).price == 0 {
            profile.selectedArenaID = arenaID
        }
        PersistenceManager.shared.save()
        AudioManager.shared.play(.button)
    }
}
