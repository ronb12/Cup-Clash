import Foundation

struct MatchState: Equatable, Sendable {
    var configuration: MatchConfiguration
    var cups: [CupData]
    var activeSide: PlayerSide
    var playerShots: Int
    var opponentShots: Int
    var playerMakes: Int
    var opponentMakes: Int
    var currentMakeStreak: Int
    var bestMakeStreak: Int
    var playerReracksUsed: Int
    var opponentReracksUsed: Int
    var isFinished: Bool
    var winner: PlayerSide?
    var lastShot: ShotResult?
    var lastScoredCupID: UUID?
    var turnIndex: Int
    var awaitingPassReady: Bool

    static let maxReracksPerSide = 1
    static let rerackCupThreshold = 3

    var playerCupsRemaining: Int {
        cups.filter { $0.owner == .opponent && $0.isActive }.count
    }

    var opponentCupsRemaining: Int {
        cups.filter { $0.owner == .player && $0.isActive }.count
    }

    var totalPlayerCups: Int { configuration.cupCount.rawValue }

    /// Cups still on this side's own rack (what the other player is shooting at).
    func rackRemaining(for side: PlayerSide) -> Int {
        cups.filter { $0.owner == side && $0.isActive }.count
    }

    func remainingCups(for side: PlayerSide) -> Int {
        side == .player ? playerCupsRemaining : opponentCupsRemaining
    }

    func canRerack(for side: PlayerSide) -> Bool {
        guard !isFinished, configuration.mode != .practice else { return false }
        let used = side == .player ? playerReracksUsed : opponentReracksUsed
        let remaining = cups.filter { $0.owner == side && $0.isActive }.count
        return used < Self.maxReracksPerSide && remaining > 0 && remaining <= Self.rerackCupThreshold
    }

    var playerAccuracy: Double {
        AccuracyMath.percent(made: playerMakes, attempted: playerShots)
    }

    var opponentAccuracy: Double {
        AccuracyMath.percent(made: opponentMakes, attempted: opponentShots)
    }
}
