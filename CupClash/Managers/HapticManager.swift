import CoreHaptics
import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    var isEnabled = true
    private var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    func button() { play(intensity: 0.35, sharpness: 0.45) }
    func throwRelease() { play(intensity: 0.62, sharpness: 0.35) }
    func table() { play(intensity: 0.28, sharpness: 0.20) }
    func rim() { play(intensity: 0.55, sharpness: 0.85) }
    func made() { play(intensity: 0.9, sharpness: 0.55) }
    func miss() { play(intensity: 0.28, sharpness: 0.18) }
    func turn() { play(intensity: 0.32, sharpness: 0.30) }
    func victory() { play(intensity: 1.0, sharpness: 0.42) }
    func coins() { play(intensity: 0.45, sharpness: 0.65) }
    func levelUp() { play(intensity: 0.8, sharpness: 0.5) }

    func apply(settings: GameSettings) {
        isEnabled = settings.hapticsEnabled
    }

    private func play(intensity: Float, sharpness: Float) {
        guard isEnabled else { return }
        if let engine {
            let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensityParam, sharpnessParam], relativeTime: 0)
            if let pattern = try? CHHapticPattern(events: [event], parameters: []),
               let player = try? engine.makePlayer(with: pattern) {
                try? player.start(atTime: 0)
                return
            }
        }
        let style: UIImpactFeedbackGenerator.FeedbackStyle = sharpness > 0.6 ? .rigid : .medium
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: CGFloat(intensity))
    }
}
