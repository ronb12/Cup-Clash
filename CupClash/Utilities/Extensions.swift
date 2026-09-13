import Foundation
import simd
import SwiftUI

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, self))
    }
}

extension SIMD3 where Scalar == Float {
    var length: Float { simd_length(self) }

    var horizontal: SIMD3<Float> {
        SIMD3(x, 0, z)
    }
}

extension Date {
    var timeIntervalSinceNowClamped: TimeInterval {
        max(0, -timeIntervalSinceNow)
    }
}

extension View {
    func cupClashCardShadow() -> some View {
        shadow(color: CupClashTheme.cyan.opacity(0.18), radius: 16, y: 8)
    }

    func accessibilityHintIfAvailable(_ text: String) -> some View {
        accessibilityHint(text)
    }
}

enum AccuracyMath {
    static func percent(made: Int, attempted: Int) -> Double {
        guard attempted > 0 else { return 0 }
        return (Double(made) / Double(attempted)) * 100
    }

    static func formatted(made: Int, attempted: Int) -> String {
        String(format: "%.0f%%", percent(made: made, attempted: attempted))
    }
}
