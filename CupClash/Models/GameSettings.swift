import Foundation
import SwiftData

@Model
final class GameSettings {
    var musicEnabled: Bool
    var soundEffectsEnabled: Bool
    var hapticsEnabled: Bool
    var aimAssistanceEnabled: Bool
    var trajectoryGuideEnabled: Bool
    var leftHandedControls: Bool
    var reducedMotion: Bool
    var highContrast: Bool
    var throwSensitivity: Double
    var preferredDifficultyRaw: String
    var preferredCupCountRaw: Int

    init(
        musicEnabled: Bool = true,
        soundEffectsEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        aimAssistanceEnabled: Bool = true,
        trajectoryGuideEnabled: Bool = true,
        leftHandedControls: Bool = false,
        reducedMotion: Bool = false,
        highContrast: Bool = false,
        throwSensitivity: Double = 1.0,
        preferredDifficultyRaw: String = AIDifficulty.rookie.rawValue,
        preferredCupCountRaw: Int = CupCount.six.rawValue
    ) {
        self.musicEnabled = musicEnabled
        self.soundEffectsEnabled = soundEffectsEnabled
        self.hapticsEnabled = hapticsEnabled
        self.aimAssistanceEnabled = aimAssistanceEnabled
        self.trajectoryGuideEnabled = trajectoryGuideEnabled
        self.leftHandedControls = leftHandedControls
        self.reducedMotion = reducedMotion
        self.highContrast = highContrast
        self.throwSensitivity = throwSensitivity
        self.preferredDifficultyRaw = preferredDifficultyRaw
        self.preferredCupCountRaw = preferredCupCountRaw
    }

    var preferredDifficulty: AIDifficulty {
        get { AIDifficulty(rawValue: preferredDifficultyRaw) ?? .rookie }
        set { preferredDifficultyRaw = newValue.rawValue }
    }

    var preferredCupCount: CupCount {
        get { CupCount(rawValue: preferredCupCountRaw) ?? .six }
        set { preferredCupCountRaw = newValue.rawValue }
    }

    var clampedSensitivity: Float {
        Float(throwSensitivity.clamped(to: 0.5...1.8))
    }
}
