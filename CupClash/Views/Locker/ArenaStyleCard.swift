import SwiftUI

struct ArenaStyleCard: View {
    let style: ArenaStyle
    let unlocked: Bool
    let selected: Bool
    let coins: Int
    let onBuy: () -> Void
    let onEquip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(style.floorColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(style.neonColor, lineWidth: 2)
                    )
                    .frame(width: 44, height: 32)
                VStack(alignment: .leading) {
                    Text(style.name)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                    Text(unlocked ? "Unlocked" : "\(style.price) coins")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(style.isPremium ? CupClashTheme.gold : CupClashTheme.textSecondary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CupClashTheme.neonGreen)
                        .accessibilityLabel("Equipped")
                }
            }
            if unlocked {
                PrimaryButton(title: selected ? "Equipped" : "Equip", enabled: !selected, action: onEquip)
            } else {
                PrimaryButton(
                    title: coins >= style.price ? "Buy" : "Need \(style.price - coins) more coins",
                    gold: style.isPremium,
                    enabled: coins >= style.price,
                    action: onBuy
                )
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18).fill(CupClashTheme.navyPanel.opacity(0.9)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(style.name), \(unlocked ? "unlocked" : "locked, \(style.price) coins")")
    }
}
