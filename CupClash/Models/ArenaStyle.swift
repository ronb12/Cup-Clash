import Foundation
import SwiftUI

struct ArenaStyle: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
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
        floorRed: 0.04, floorGreen: 0.05, floorBlue: 0.10,
        neonRed: 0.00, neonGreen: 0.91, neonBlue: 0.98
    )

    static let violetHall = ArenaStyle(
        id: "arena.violet",
        name: "Violet Hall",
        floorRed: 0.07, floorGreen: 0.03, floorBlue: 0.12,
        neonRed: 0.62, neonGreen: 0.28, neonBlue: 0.98
    )

    static let catalog: [ArenaStyle] = [neonCourt, violetHall]

    static func style(id: String) -> ArenaStyle {
        catalog.first(where: { $0.id == id }) ?? neonCourt
    }
}
