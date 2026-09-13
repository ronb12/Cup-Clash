import Foundation

enum GameMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case quickMatch
    case passAndPlay
    case practice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickMatch: "Quick Match"
        case .passAndPlay: "Pass & Play"
        case .practice: "Practice"
        }
    }

    var detail: String {
        switch self {
        case .quickMatch: "Challenge a computer rival"
        case .passAndPlay: "Two players, one device"
        case .practice: "Unlimited throws and resets"
        }
    }

    var symbolName: String {
        switch self {
        case .quickMatch: "bolt.fill"
        case .passAndPlay: "person.2.fill"
        case .practice: "target"
        }
    }

    var awardsCoins: Bool { self == .quickMatch }
}

enum AIDifficulty: String, CaseIterable, Codable, Identifiable, Sendable {
    case rookie
    case pro
    case champion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rookie: "Rookie"
        case .pro: "Pro"
        case .champion: "Champion"
        }
    }

    var detail: String {
        switch self {
        case .rookie: "Wide aim, shaky power"
        case .pro: "Balanced and dangerous"
        case .champion: "Tight, fair, and fast"
        }
    }

    var winCoins: Int {
        switch self {
        case .rookie: AppConstants.rookieWinCoins
        case .pro: AppConstants.proWinCoins
        case .champion: AppConstants.championWinCoins
        }
    }
}

struct MatchConfiguration: Hashable, Codable, Sendable {
    var mode: GameMode
    var difficulty: AIDifficulty
    var cupCount: CupCount
    var formation: CupFormation
    var aimAssistance: Bool
    var playerName: String
    var opponentName: String
    var movingTargets: Bool
    var seed: UInt64

    static func quickMatch(
        difficulty: AIDifficulty,
        cupCount: CupCount,
        formation: CupFormation = .triangle,
        aimAssistance: Bool,
        playerName: String
    ) -> MatchConfiguration {
        MatchConfiguration(
            mode: .quickMatch,
            difficulty: difficulty,
            cupCount: cupCount,
            formation: formation,
            aimAssistance: aimAssistance,
            playerName: playerName,
            opponentName: difficulty.title,
            movingTargets: false,
            seed: UInt64.random(in: 1...UInt64.max)
        )
    }
}
