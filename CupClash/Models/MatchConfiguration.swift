import Foundation

enum GameMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case quickMatch
    case passAndPlay
    case practice
    case dailyChallenge
    case tournament
    case challenge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickMatch: "Quick Match"
        case .passAndPlay: "Pass & Play"
        case .practice: "Practice"
        case .dailyChallenge: "Daily Challenge"
        case .tournament: "Tournament"
        case .challenge: "Challenge"
        }
    }

    var detail: String {
        switch self {
        case .quickMatch: "Challenge a computer rival"
        case .passAndPlay: "Two players, one device"
        case .practice: "Unlimited throws and resets"
        case .dailyChallenge: "A new seeded match every day"
        case .tournament: "A weekly three-round cup"
        case .challenge: "Special rules and objectives"
        }
    }

    var symbolName: String {
        switch self {
        case .quickMatch: "bolt.fill"
        case .passAndPlay: "person.2.fill"
        case .practice: "target"
        case .dailyChallenge: "calendar.badge.clock"
        case .tournament: "trophy.fill"
        case .challenge: "flag.checkered"
        }
    }

    var usesAI: Bool {
        self == .quickMatch || self == .dailyChallenge || self == .tournament || self == .challenge
    }
    var awardsCoins: Bool { usesAI }
    var isRanked: Bool { usesAI }
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
    var suddenDeathMakes: Int
    var eventID: String
    var eventRound: Int
    var eventTitle: String
    var lockAimAssistOff: Bool

    var isSuddenDeath: Bool { suddenDeathMakes > 0 }
    var isFinalTournamentRound: Bool { mode == .tournament && eventRound >= 3 }

    init(
        mode: GameMode,
        difficulty: AIDifficulty,
        cupCount: CupCount,
        formation: CupFormation,
        aimAssistance: Bool,
        playerName: String,
        opponentName: String,
        movingTargets: Bool,
        seed: UInt64,
        suddenDeathMakes: Int = 0,
        eventID: String = "",
        eventRound: Int = 0,
        eventTitle: String = "",
        lockAimAssistOff: Bool = false
    ) {
        self.mode = mode
        self.difficulty = difficulty
        self.cupCount = cupCount
        self.formation = formation
        self.aimAssistance = aimAssistance
        self.playerName = playerName
        self.opponentName = opponentName
        self.movingTargets = movingTargets
        self.seed = seed
        self.suddenDeathMakes = suddenDeathMakes
        self.eventID = eventID
        self.eventRound = eventRound
        self.eventTitle = eventTitle
        self.lockAimAssistOff = lockAimAssistOff
    }

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
