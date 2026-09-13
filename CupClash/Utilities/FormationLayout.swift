import Foundation
import simd

enum CupFormation: String, CaseIterable, Codable, Identifiable, Sendable {
    case triangle
    case diamond
    case straight
    case randomized

    var id: String { rawValue }

    var title: String {
        switch self {
        case .triangle: "Triangle"
        case .diamond: "Diamond"
        case .straight: "Straight Line"
        case .randomized: "Random Legal"
        }
    }

    var symbolName: String {
        switch self {
        case .triangle: "triangle.fill"
        case .diamond: "diamond.fill"
        case .straight: "equal"
        case .randomized: "shuffle"
        }
    }
}

enum CupCount: Int, CaseIterable, Codable, Identifiable, Sendable {
    case six = 6
    case ten = 10

    var id: Int { rawValue }
    var title: String { rawValue == 6 ? "Six Cups" : "Ten Cups" }
}

struct FormationLayout: Equatable, Sendable {
    /// Local XZ offsets centered on the rack, pointing toward +Z (toward mid-table).
    let offsets: [SIMD2<Float>]

    static func make(_ formation: CupFormation, count: CupCount, seed: UInt64 = 0) -> FormationLayout {
        switch formation {
        case .triangle:
            return FormationLayout(offsets: triangle(count: count.rawValue))
        case .diamond:
            return FormationLayout(offsets: diamond(count: count.rawValue))
        case .straight:
            return FormationLayout(offsets: straight(count: count.rawValue))
        case .randomized:
            let legal: [CupFormation] = [.triangle, .diamond, .straight]
            var rng = SeededGenerator(seed: seed == 0 ? UInt64.random(in: 1...UInt64.max) : seed)
            let pick = legal.randomElement(using: &rng) ?? .triangle
            var layout = make(pick, count: count, seed: seed)
            layout = layout.jittered(using: &rng)
            return layout
        }
    }

    static func rerack(remaining: Int) -> FormationLayout {
        if remaining <= 1 {
            return FormationLayout(offsets: [.zero])
        }
        if remaining == 2 {
            return FormationLayout(offsets: [SIMD2(-0.048, 0), SIMD2(0.048, 0)])
        }
        return FormationLayout(offsets: triangle(count: remaining))
    }

    func worldPositions(ownerIsNear: Bool, tableHalfLength: Float = ArenaMetrics.tableHalfLength) -> [SIMD3<Float>] {
        let zBase = ownerIsNear
            ? tableHalfLength - ArenaMetrics.cupInset
            : -tableHalfLength + ArenaMetrics.cupInset
        let zSign: Float = ownerIsNear ? -1 : 1
        return offsets.map { offset in
            SIMD3(
                offset.x,
                ArenaMetrics.tableSurfaceY,
                zBase + offset.y * zSign
            )
        }
    }

    private func jittered(using rng: inout SeededGenerator) -> FormationLayout {
        let jittered = offsets.map { point in
            SIMD2(
                point.x + Float.random(in: -0.012...0.012, using: &rng),
                point.y + Float.random(in: -0.010...0.010, using: &rng)
            )
        }
        return FormationLayout(offsets: jittered)
    }

    private static func triangle(count: Int) -> [SIMD2<Float>] {
        let rows = triangleRows(for: count)
        return packedRows(rows)
    }

    private static func diamond(count: Int) -> [SIMD2<Float>] {
        if count >= 10 {
            return packedRows([1, 2, 3, 2, 2])
        }
        return packedRows([1, 2, 1, 2])
    }

    private static func straight(count: Int) -> [SIMD2<Float>] {
        strideCenters(count: count, spacing: ArenaMetrics.cupSpacing).map { SIMD2($0, 0) }
    }

    private static func packedRows(_ rows: [Int]) -> [SIMD2<Float>] {
        let spacing = ArenaMetrics.cupSpacing
        let depth = Float(max(rows.count - 1, 0)) * spacing
        var points: [SIMD2<Float>] = []
        for (rowIndex, cupsInRow) in rows.enumerated() {
            let z = -depth / 2 + Float(rowIndex) * spacing
            let xs = strideCenters(count: cupsInRow, spacing: spacing)
            for x in xs {
                points.append(SIMD2(x, z))
            }
        }
        return points
    }

    private static func triangleRows(for count: Int) -> [Int] {
        switch count {
        case 1: [1]
        case 2: [1, 1]
        case 3: [1, 2]
        case 4: [1, 2, 1]
        case 5: [1, 2, 2]
        case 6: [1, 2, 3]
        case 7: [1, 2, 3, 1]
        case 8: [1, 2, 3, 2]
        case 9: [1, 2, 3, 3]
        default: [1, 2, 3, 4]
        }
    }

    private static func strideCenters(count: Int, spacing: Float) -> [Float] {
        guard count > 0 else { return [] }
        let width = Float(count - 1) * spacing
        return (0..<count).map { index in
            -width / 2 + Float(index) * spacing
        }
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xC0FFEE : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
