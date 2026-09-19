import Foundation
import SwiftUI

struct ArenaStyle: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let price: Int
    let isPremium: Bool
    let floorRed: Double
    let floorGreen: Double
    let floorBlue: Double
    let neonRed: Double
    let neonGreen: Double
    let neonBlue: Double

    var floorColor: Color {
        Color(red: floorRed, green: floorGreen, blue: floorBlue)
    }

    var neonColor: Color {
        Color(red: neonRed, green: neonGreen, blue: neonBlue)
    }

    static let neonCourt = ArenaStyle(
        id: "arena.neon",
        name: "Neon Court",
        price: 0,
        isPremium: false,
        floorRed: 0.04, floorGreen: 0.05, floorBlue: 0.10,
        neonRed: 0.00, neonGreen: 0.91, neonBlue: 0.98
    )

    static let violetHall = ArenaStyle(
        id: "arena.violet",
        name: "Violet Hall",
        price: 150,
        isPremium: false,
        floorRed: 0.07, floorGreen: 0.03, floorBlue: 0.12,
        neonRed: 0.62, neonGreen: 0.28, neonBlue: 0.98
    )

    static let midnightAlley = ArenaStyle(
        id: "arena.midnight",
        name: "Midnight Alley",
        price: 300,
        isPremium: false,
        floorRed: 0.02, floorGreen: 0.03, floorBlue: 0.06,
        neonRed: 0.22, neonGreen: 0.98, neonBlue: 0.45
    )

    static let sunsetDeck = ArenaStyle(
        id: "arena.sunset",
        name: "Sunset Deck",
        price: 450,
        isPremium: true,
        floorRed: 0.10, floorGreen: 0.04, floorBlue: 0.05,
        neonRed: 1.00, neonGreen: 0.58, neonBlue: 0.18
    )

    static let catalog: [ArenaStyle] = [neonCourt, violetHall, midnightAlley, sunsetDeck]

    static func style(id: String) -> ArenaStyle {
        catalog.first(where: { $0.id == id }) ?? neonCourt
    }
}
