import Foundation

enum DailyChallenge {
    static func dayID(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 2026
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func seed(for date: Date = Date(), calendar: Calendar = .current) -> UInt64 {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = UInt64(parts.year ?? 2026)
        let month = UInt64(parts.month ?? 1)
        let day = UInt64(parts.day ?? 1)
        return year * 10_000 + month * 100 + day
    }

    static func configuration(
        playerName: String,
        aimAssistance: Bool,
        date: Date = Date(),
        calendar: Calendar = .current
    ) -> MatchConfiguration {
        let seed = seed(for: date, calendar: calendar)
        let difficulties = AIDifficulty.allCases
        let formations: [CupFormation] = [.triangle, .diamond, .straight]
        let difficulty = difficulties[Int(seed % UInt64(difficulties.count))]
        let formation = formations[Int(seed / 3 % UInt64(formations.count))]
        let cups: CupCount = seed.isMultiple(of: 2) ? .six : .ten
        return MatchConfiguration(
            mode: .dailyChallenge,
            difficulty: difficulty,
            cupCount: cups,
            formation: formation,
            aimAssistance: aimAssistance,
            playerName: playerName,
            opponentName: "Daily \(difficulty.title)",
            movingTargets: seed.isMultiple(of: 5),
            seed: seed
        )
    }

    static func score(makes: Int, won: Bool) -> Int {
        makes * 10 + (won ? 50 : 0)
    }
}
