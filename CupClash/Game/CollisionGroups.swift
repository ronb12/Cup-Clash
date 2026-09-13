import Foundation
import RealityKit

enum CollisionGroups {
    static var ball: CollisionGroup { CollisionGroup(rawValue: 1 << 1) }
    static var table: CollisionGroup { CollisionGroup(rawValue: 1 << 2) }
    static var cup: CollisionGroup { CollisionGroup(rawValue: 1 << 3) }
    static var trigger: CollisionGroup { CollisionGroup(rawValue: 1 << 4) }
    static var bounds: CollisionGroup { CollisionGroup(rawValue: 1 << 5) }

    static var ballFilter: CollisionFilter { CollisionFilter(group: ball, mask: [table, cup, trigger, bounds]) }
    static var tableFilter: CollisionFilter { CollisionFilter(group: table, mask: [ball]) }
    static var cupFilter: CollisionFilter { CollisionFilter(group: cup, mask: [ball]) }
    static var triggerFilter: CollisionFilter { CollisionFilter(group: trigger, mask: [ball]) }
    static var boundsFilter: CollisionFilter { CollisionFilter(group: bounds, mask: [ball]) }
}

enum EntityNames {
    static let table = "table.surface"
    static let tableTrim = "table.trim"
    static let ball = "ball.active"
    static let triggerPrefix = "cup.trigger."
    static let wallPrefix = "cup.wall."
    static let cupPrefix = "cup.root."
    static let celebrationPrefix = "fx.celebrate."

    static func trigger(_ id: UUID) -> String { triggerPrefix + id.uuidString }
    static func wall(_ id: UUID) -> String { wallPrefix + id.uuidString }
    static func cup(_ id: UUID) -> String { cupPrefix + id.uuidString }

    static func cupID(from name: String) -> UUID? {
        let prefixes = [triggerPrefix, wallPrefix, cupPrefix]
        for prefix in prefixes where name.hasPrefix(prefix) {
            return UUID(uuidString: String(name.dropFirst(prefix.count)))
        }
        return nil
    }
}
