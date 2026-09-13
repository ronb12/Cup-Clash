import Foundation
import SwiftUI

struct BallStyle: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let price: Int
    let red: Double
    let green: Double
    let blue: Double
    let metallic: Double
    let emissive: Double
    let isPremium: Bool

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var isFree: Bool { price == 0 }

    static let catalog: [BallStyle] = [
        BallStyle(id: "ball.classic", name: "Classic White", price: 0, red: 0.96, green: 0.97, blue: 0.99, metallic: 0.05, emissive: 0.0, isPremium: false),
        BallStyle(id: "ball.cyan", name: "Neon Cyan", price: 150, red: 0.05, green: 0.92, blue: 0.98, metallic: 0.25, emissive: 0.45, isPremium: false),
        BallStyle(id: "ball.violet", name: "Violet Pulse", price: 250, red: 0.62, green: 0.28, blue: 0.98, metallic: 0.3, emissive: 0.4, isPremium: false),
        BallStyle(id: "ball.gold", name: "Golden Champion", price: 500, red: 1.0, green: 0.80, blue: 0.24, metallic: 0.85, emissive: 0.25, isPremium: true),
        BallStyle(id: "ball.galaxy", name: "Galaxy", price: 750, red: 0.22, green: 0.16, blue: 0.48, metallic: 0.7, emissive: 0.55, isPremium: true)
    ]

    static func style(id: String) -> BallStyle {
        catalog.first(where: { $0.id == id }) ?? catalog[0]
    }
}
