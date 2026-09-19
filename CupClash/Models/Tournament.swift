import Foundation

enum TournamentEvent {
    static let opponentPool = ["Kai", "Nova", "Rio", "Mira", "Hex", "Jett", "Skye", "Remy"]
    static let cupNames = ["Neon Cup", "Violet Cup", "Midnight Cup", "Sunset Cup"]

    static func weekID(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return String(format: "%04d-W%02d", year, week)
    }

    static func seed(for date: Date = Date(), calendar: Calendar = .current) -> UInt64 {
        let year = UInt64(calendar.component(.yearForWeekOfYear, from: date))
        let week = UInt64(calendar.component(.weekOfYear, from: date))
        return year * 100 + week
    }

    static func current(date: Date = Date(), calendar: Calendar = .current) -> WeeklyTournament {
        make(weekID: weekID(for: date, calendar: calendar), seed: seed(for: date, calendar: calendar))
    }

    static func make(weekID: String, seed: UInt64) -> WeeklyTournament {
        let names = uniqueOpponents(seed: seed)
        let cup = cupNames[Int(seed % UInt64(cupNames.count))]
        let formations: [CupFormation] = [.triangle, .diamond, .straight]
        let rounds = [
            TournamentRound(
                index: 1,
                title: "Opening Match",
                opponentName: names[0],
                difficulty: .rookie,
                cupCount: .six,
                formation: formations[Int(seed % 3)],
                suddenDeathMakes: 0,
                movingTargets: false,
                seed: seed * 10 + 1
            ),
            TournamentRound(
                index: 2,
                title: "Semifinal",
                opponentName: names[1],
                difficulty: .pro,
                cupCount: .six,
                formation: formations[Int(seed / 3 % 3)],
                suddenDeathMakes: seed.isMultiple(of: 4) ? 3 : 0,
                movingTargets: false,
                seed: seed * 10 + 2
            ),
            TournamentRound(
                index: 3,
                title: "Final",
                opponentName: names[2],
                difficulty: .champion,
                cupCount: .ten,
                formation: .triangle,
                suddenDeathMakes: 0,
                movingTargets: seed.isMultiple(of: 5),
                seed: seed * 10 + 3
            )
        ]
        return WeeklyTournament(weekID: weekID, title: cup, rounds: rounds)
    }

    static func uniqueOpponents(seed: UInt64) -> [String] {
        var picks: [String] = []
        var cursor = Int(seed % UInt64(opponentPool.count))
        while picks.count < 3 {
            let name = opponentPool[cursor % opponentPool.count]
            if !picks.contains(name) {
                picks.append(name)
            }
            cursor += 1 + Int(seed / UInt64(picks.count + 1) % 3)
        }
        return picks
    }
}

struct WeeklyTournament: Hashable, Sendable {
    var weekID: String
    var title: String
    var rounds: [TournamentRound]

    func round(_ index: Int) -> TournamentRound? {
        rounds.first(where: { $0.index == index })
    }

    func configuration(round index: Int, playerName: String, aimAssistance: Bool) -> MatchConfiguration? {
        guard let round = round(index) else { return nil }
        return round.configuration(weekID: weekID, cupTitle: title, playerName: playerName, aimAssistance: aimAssistance)
    }
}

struct TournamentRound: Identifiable, Hashable, Sendable {
    var id: Int { index }
    var index: Int
    var title: String
    var opponentName: String
    var difficulty: AIDifficulty
    var cupCount: CupCount
    var formation: CupFormation
    var suddenDeathMakes: Int
    var movingTargets: Bool
    var seed: UInt64

    func configuration(
        weekID: String,
        cupTitle: String,
        playerName: String,
        aimAssistance: Bool
    ) -> MatchConfiguration {
        MatchConfiguration(
            mode: .tournament,
            difficulty: difficulty,
            cupCount: cupCount,
            formation: formation,
            aimAssistance: aimAssistance,
            playerName: playerName,
            opponentName: opponentName,
            movingTargets: movingTargets,
            seed: seed,
            suddenDeathMakes: suddenDeathMakes,
            eventID: weekID,
            eventRound: index,
            eventTitle: "\(cupTitle) • \(title)",
            lockAimAssistOff: false
        )
    }
}

enum TournamentRoundStatus: String, Sendable {
    case locked
    case current
    case won
    case lost
}
