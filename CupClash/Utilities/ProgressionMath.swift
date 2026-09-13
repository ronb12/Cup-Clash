import Foundation

enum ProgressionMath {
    /// XP required to go from `level` to `level + 1`.
    /// Level 1 → 2 costs 250. Each later level adds 50 more.
    static func xpRequired(from level: Int) -> Int {
        let safeLevel = max(1, level)
        return AppConstants.baseLevelXP + AppConstants.extraLevelXP * (safeLevel - 1)
    }

    /// Lifetime XP needed to *reach* `level` (level 1 is 0).
    static func totalXP(toReach level: Int) -> Int {
        guard level > 1 else { return 0 }
        var total = 0
        for current in 1..<level {
            total += xpRequired(from: current)
        }
        return total
    }

    static func level(forTotalXP totalXP: Int) -> Int {
        var level = 1
        var remaining = max(0, totalXP)
        while remaining >= xpRequired(from: level) {
            remaining -= xpRequired(from: level)
            level += 1
            if level > 200 { break }
        }
        return level
    }

    static func progress(totalXP: Int) -> (level: Int, intoLevel: Int, needed: Int, fraction: Double) {
        let currentLevel = level(forTotalXP: totalXP)
        let floorXP = self.totalXP(toReach: currentLevel)
        let intoLevel = max(0, totalXP - floorXP)
        let needed = xpRequired(from: currentLevel)
        let fraction = needed == 0 ? 1 : Double(intoLevel) / Double(needed)
        return (currentLevel, intoLevel, needed, min(1, max(0, fraction)))
    }
}
