import Foundation
import simd

/// Turns where a missed ball first landed into a short coaching hint.
enum MissHint {
    /// - Parameters:
    ///   - landing: world position where the ball first touched the table.
    ///   - cups: live target cups for the throwing side.
    ///   - towardNegativeZ: true when the thrower stands on the +z end.
    static func describe(landing: SIMD3<Float>, cups: [SIMD3<Float>], towardNegativeZ: Bool) -> String? {
        guard !cups.isEmpty else { return nil }
        func depth(_ z: Float) -> Float { towardNegativeZ ? -z : z }
        let depths = cups.map { depth($0.z) }
        guard let front = depths.min(), let back = depths.max() else { return nil }
        let margin: Float = 0.05
        let landed = depth(landing.z)
        if landed < front - margin { return "Short — add power" }
        if landed > back + margin { return "Long — ease off" }
        guard let nearest = cups.min(by: {
            hypotf($0.x - landing.x, $0.z - landing.z) < hypotf($1.x - landing.x, $1.z - landing.z)
        }) else { return nil }
        let rightSign: Float = towardNegativeZ ? 1 : -1
        let offset = (landing.x - nearest.x) * rightSign
        if offset > margin { return "Too far right" }
        if offset < -margin { return "Too far left" }
        return nil
    }
}
