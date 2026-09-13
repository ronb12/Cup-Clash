import Foundation
import simd

enum PlayerSide: String, Codable, CaseIterable, Sendable {
    case player
    case opponent

    var displayTitle: String {
        switch self {
        case .player: "You"
        case .opponent: "Rival"
        }
    }

    var opposite: PlayerSide {
        self == .player ? .opponent : .player
    }
}

enum ShotResult: String, Codable, CaseIterable, Sendable {
    case made
    case missed
    case rimOut
    case tableBounce
    case outOfBounds
    case timeout

    var title: String {
        switch self {
        case .made: "CUP!"
        case .missed: "Miss"
        case .rimOut: "Rim Out"
        case .tableBounce: "Table"
        case .outOfBounds: "Out"
        case .timeout: "Time"
        }
    }

    var spokenLabel: String {
        switch self {
        case .made: "Cup scored"
        case .missed: "Shot missed"
        case .rimOut: "Ball hit the rim and missed"
        case .tableBounce: "Ball bounced on the table"
        case .outOfBounds: "Ball went out of bounds"
        case .timeout: "Shot timed out"
        }
    }

    var isSuccess: Bool { self == .made }
}

struct CupData: Identifiable, Hashable, Codable, Sendable {
    var id: UUID
    var owner: PlayerSide
    var rackIndex: Int
    var isActive: Bool
    var localOffset: SIMD2<Float>
    var worldPosition: SIMD3<Float>

    init(
        id: UUID = UUID(),
        owner: PlayerSide,
        rackIndex: Int,
        isActive: Bool = true,
        localOffset: SIMD2<Float>,
        worldPosition: SIMD3<Float>
    ) {
        self.id = id
        self.owner = owner
        self.rackIndex = rackIndex
        self.isActive = isActive
        self.localOffset = localOffset
        self.worldPosition = worldPosition
    }
}

extension SIMD2: Codable where Scalar: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Scalar.self)
        let y = try container.decode(Scalar.self)
        self.init(x, y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}

extension SIMD3: Codable where Scalar: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Scalar.self)
        let y = try container.decode(Scalar.self)
        let z = try container.decode(Scalar.self)
        self.init(x, y, z)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
        try container.encode(z)
    }
}
