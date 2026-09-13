import Foundation
import SwiftUI

struct CupStyle: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let price: Int
    let red: Double
    let green: Double
    let blue: Double
    let rimRed: Double
    let rimGreen: Double
    let rimBlue: Double
    let isRainbow: Bool
    let isPremium: Bool

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var rimColor: Color {
        Color(red: rimRed, green: rimGreen, blue: rimBlue)
    }

    var isFree: Bool { price == 0 }

    static let catalog: [CupStyle] = [
        CupStyle(id: "cup.classic", name: "Classic Red", price: 0, red: 0.90, green: 0.16, blue: 0.18, rimRed: 0.98, rimGreen: 0.86, rimBlue: 0.72, isRainbow: false, isPremium: false),
        CupStyle(id: "cup.blue", name: "Electric Blue", price: 150, red: 0.08, green: 0.46, blue: 0.98, rimRed: 0.75, rimGreen: 0.92, rimBlue: 1.0, isRainbow: false, isPremium: false),
        CupStyle(id: "cup.violet", name: "Neon Violet", price: 250, red: 0.56, green: 0.22, blue: 0.96, rimRed: 0.90, rimGreen: 0.78, rimBlue: 1.0, isRainbow: false, isPremium: false),
        CupStyle(id: "cup.gold", name: "Midnight Gold", price: 500, red: 0.16, green: 0.12, blue: 0.08, rimRed: 1.0, rimGreen: 0.80, rimBlue: 0.24, isRainbow: false, isPremium: true),
        CupStyle(id: "cup.rainbow", name: "Rainbow Clash", price: 750, red: 0.95, green: 0.22, blue: 0.55, rimRed: 0.20, rimGreen: 0.95, rimBlue: 0.85, isRainbow: true, isPremium: true)
    ]

    static func style(id: String) -> CupStyle {
        catalog.first(where: { $0.id == id }) ?? catalog[0]
    }
}
