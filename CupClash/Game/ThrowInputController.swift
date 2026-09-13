import Foundation
import SwiftUI

@MainActor
@Observable
final class ThrowInputController {
    var aim: Float = 0
    var power: Float = 0
    var isAiming = false

    func begin() {
        isAiming = true
        aim = 0
        power = 0
    }

    func update(translation: CGSize, sensitivity: Float, leftHanded: Bool) {
        let horizontal = Float(translation.width) * 0.0044 * sensitivity
        aim = (leftHanded ? -horizontal : horizontal).clamped(to: -1...1)
        let pullback = Float(translation.height) * 0.0036 * sensitivity
        power = pullback.clamped(to: 0...1)
    }

    func commit(minimumPower: Float) -> (aim: Float, power: Float)? {
        let resultAim = aim
        let resultPower = power
        reset()
        guard resultPower >= minimumPower else { return nil }
        return (resultAim, resultPower)
    }

    func cancel() {
        reset()
    }

    func reset() {
        isAiming = false
        aim = 0
        power = 0
    }
}
