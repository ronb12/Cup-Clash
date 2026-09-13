import Foundation
import RealityKit

enum CupRackBuilder {
    @MainActor
    static func build(cups: [CupData], style: CupStyle) -> [UUID: Entity] {
        var map: [UUID: Entity] = [:]
        for (index, cup) in cups.enumerated() where cup.isActive {
            map[cup.id] = CupFactory.make(data: cup, style: style, index: index)
        }
        return map
    }
}
