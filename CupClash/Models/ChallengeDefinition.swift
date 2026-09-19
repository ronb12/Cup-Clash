import Foundation

struct ChallengeDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let rewardCoins: Int

    static let daily = ChallengeDefinition(
        id: "daily",
        title: "Daily Challenge",
        detail: "Win today's seeded match.",
        symbolName: "calendar.badge.clock",
        rewardCoins: 40
    )

    static let movingMayhem = ChallengeDefinition(
        id: "moving_mayhem",
        title: "Moving Mayhem",
        detail: "Win while the rival cups sway.",
        symbolName: "water.waves",
        rewardCoins: 40
    )

    static let tenCup = ChallengeDefinition(
        id: "ten_cup",
        title: "Ten-Cup Gauntlet",
        detail: "Clear a Champion ten-cup rack.",
        symbolName: "square.grid.3x3.fill",
        rewardCoins: 55
    )

    static let clutchThree = ChallengeDefinition(
        id: "clutch_three",
        title: "Clutch Three",
        detail: "Win Sudden Death, first to 3.",
        symbolName: "bolt.heart.fill",
        rewardCoins: 35
    )

    static let noAssist = ChallengeDefinition(
        id: "no_assist",
        title: "Free Aim",
        detail: "Win with aim assistance locked off.",
        symbolName: "scope",
        rewardCoins: 40
    )

    static let perfectRack = ChallengeDefinition(
        id: "perfect_rack",
        title: "Perfect Rack",
        detail: "Win without missing a throw.",
        symbolName: "sparkles",
        rewardCoins: 50
    )

    static let hotStreak = ChallengeDefinition(
        id: "hot_streak",
        title: "Hot Streak",
        detail: "Win with a 3-cup make streak.",
        symbolName: "flame.fill",
        rewardCoins: 35
    )

    static let cleanSheet = ChallengeDefinition(
        id: "clean_sheet",
        title: "Clean Sheet",
        detail: "Win without the rival making a cup.",
        symbolName: "shield.checkered",
        rewardCoins: 45
    )

    static let all: [ChallengeDefinition] = [
        daily, movingMayhem, tenCup, clutchThree, noAssist, perfectRack, hotStreak, cleanSheet
    ]

    static func definition(id: String) -> ChallengeDefinition? {
        all.first(where: { $0.id == id })
    }

    static func rewardCoins(for eventID: String) -> Int {
        definition(id: eventID)?.rewardCoins ?? 30
    }

    static func featuredIDs(for date: Date = Date(), calendar: Calendar = .current) -> [String] {
        let seed = TournamentEvent.seed(for: date, calendar: calendar)
        let playable = all.filter { $0.id != daily.id }
        let first = playable[Int(seed % UInt64(playable.count))]
        var second = playable[Int(seed / 5 % UInt64(playable.count))]
        if second.id == first.id {
            second = playable[(playable.firstIndex(where: { $0.id == first.id })! + 1) % playable.count]
        }
        return [first.id, second.id]
    }

    func configuration(playerName: String, aimAssistance: Bool) -> MatchConfiguration {
        switch id {
        case Self.daily.id:
            return DailyChallenge.configuration(playerName: playerName, aimAssistance: aimAssistance)
        case Self.movingMayhem.id:
            return make(playerName: playerName, difficulty: .pro, cups: .six, formation: .diamond, aim: aimAssistance, moving: true)
        case Self.tenCup.id:
            return make(playerName: playerName, difficulty: .champion, cups: .ten, formation: .triangle, aim: aimAssistance)
        case Self.clutchThree.id:
            return make(playerName: playerName, difficulty: .pro, cups: .six, formation: .triangle, aim: aimAssistance, sudden: 3)
        case Self.noAssist.id:
            return make(playerName: playerName, difficulty: .pro, cups: .six, formation: .straight, aim: false, lockAssistOff: true)
        case Self.perfectRack.id:
            return make(playerName: playerName, difficulty: .rookie, cups: .six, formation: .triangle, aim: aimAssistance)
        case Self.hotStreak.id:
            return make(playerName: playerName, difficulty: .pro, cups: .six, formation: .diamond, aim: aimAssistance)
        case Self.cleanSheet.id:
            return make(playerName: playerName, difficulty: .rookie, cups: .six, formation: .triangle, aim: aimAssistance)
        default:
            return make(playerName: playerName, difficulty: .pro, cups: .six, formation: .triangle, aim: aimAssistance)
        }
    }

    func isSatisfied(by result: MatchResult) -> Bool {
        guard result.playerWon else { return false }
        switch id {
        case Self.daily.id:
            return result.configuration.mode == .dailyChallenge
        case Self.movingMayhem.id:
            return result.configuration.eventID == id && result.configuration.movingTargets
        case Self.tenCup.id:
            return result.configuration.eventID == id && result.configuration.cupCount == .ten
        case Self.clutchThree.id:
            return result.configuration.eventID == id && result.configuration.isSuddenDeath
        case Self.noAssist.id:
            return result.configuration.eventID == id && result.configuration.lockAimAssistOff
        case Self.perfectRack.id:
            return result.perfectGame
        case Self.hotStreak.id:
            return result.bestStreak >= 3
        case Self.cleanSheet.id:
            return result.opponentMakes == 0
        default:
            return result.configuration.eventID == id
        }
    }

    private func make(
        playerName: String,
        difficulty: AIDifficulty,
        cups: CupCount,
        formation: CupFormation,
        aim: Bool,
        moving: Bool = false,
        sudden: Int = 0,
        lockAssistOff: Bool = false
    ) -> MatchConfiguration {
        MatchConfiguration(
            mode: id == Self.daily.id ? .dailyChallenge : .challenge,
            difficulty: difficulty,
            cupCount: cups,
            formation: formation,
            aimAssistance: aim,
            playerName: playerName,
            opponentName: title,
            movingTargets: moving,
            seed: UInt64.random(in: 1...UInt64.max),
            suddenDeathMakes: sudden,
            eventID: id,
            eventRound: 0,
            eventTitle: title,
            lockAimAssistOff: lockAssistOff
        )
    }
}
