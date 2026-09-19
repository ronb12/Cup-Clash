import Foundation

/// Decides where aim assistance may be used, so results stay fair and comparable.
enum AimAssistPolicy {
    /// Assist is a learning aid, available only against Rookie (on by default there).
    static func defaultEnabled(for difficulty: AIDifficulty) -> Bool {
        difficulty == .rookie
    }

    /// Whether assist can be switched on at all for a match.
    static func isAllowed(mode: GameMode, difficulty: AIDifficulty, lockedOff: Bool) -> Bool {
        if lockedOff { return false }
        switch mode {
        case .tournament, .dailyChallenge:
            return false // scores feed brackets and leaderboards
        default:
            break
        }
        if mode.usesAI && difficulty != .rookie { return false } // Pro and Champion are unassisted
        return true
    }

    /// Short explanation shown when assist is unavailable.
    static func lockedReason(mode: GameMode, difficulty: AIDifficulty) -> String {
        switch mode {
        case .tournament, .dailyChallenge:
            return "Aim assistance is off in ranked play so scores stay comparable."
        default:
            if mode.usesAI && difficulty != .rookie {
                return "Aim assistance is only available against Rookie."
            }
            return "Aim assistance is off for this challenge."
        }
    }
}

extension MatchConfiguration {
    var aimAssistAllowed: Bool {
        AimAssistPolicy.isAllowed(mode: mode, difficulty: difficulty, lockedOff: lockAimAssistOff)
    }

    /// True only when the player asked for assist and the rules allow it.
    var aimAssistActive: Bool { aimAssistAllowed && aimAssistance }
}
