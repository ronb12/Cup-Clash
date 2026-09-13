import SwiftUI

struct CupStyleCard: View {
    let style: CupStyle
    let unlocked: Bool
    let selected: Bool
    let coins: Int
    let onBuy: () -> Void
    let onEquip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(style.color)
                    .frame(width: 28, height: 36)
                    .overlay(alignment: .top) {
                        Capsule().fill(style.rimColor).frame(height: 6)
                    }
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
                    title: coins >= style.price ? "Buy" : "Need coins",
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
