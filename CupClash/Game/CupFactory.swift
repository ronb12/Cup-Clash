import RealityKit
import UIKit

enum CupFactory {
    @MainActor
    static func make(data: CupData, style: CupStyle, index: Int) -> Entity {
        let root = Entity()
        root.name = EntityNames.cup(data.id)
        root.position = data.worldPosition

        let visual = makeVisual(style: style, index: index)
        root.addChild(visual)
        addColliders(to: root, id: data.id)
        addTrigger(to: root, id: data.id)
        addDrink(to: root, style: style, index: index)
        return root
    }

    static func highlight(_ cup: Entity, active: Bool) {
        guard let model = cup.findEntity(named: "cup.visual") as? ModelEntity else { return }
        var material = SimpleMaterial()
        material.color = .init(tint: active ? UIColor(red: 0.2, green: 0.98, blue: 0.7, alpha: 1) : UIColor.white)
        if active {
            model.model?.materials = [material]
        }
    }

    private static func makeVisual(style: CupStyle, index: Int) -> ModelEntity {
        let mesh = ProceduralMeshes.frustum(
            bottomRadius: ArenaMetrics.cupBottomRadius,
            topRadius: ArenaMetrics.cupTopRadius,
            height: ArenaMetrics.cupHeight
        ) ?? ProceduralMeshes.cylinder(height: ArenaMetrics.cupHeight, radius: ArenaMetrics.cupTopRadius)

        let color = visualColor(style: style, index: index)
        var material = SimpleMaterial()
        material.color = .init(tint: color)
        material.roughness = 0.42
        material.metallic = 0.08
        let body = ModelEntity(mesh: mesh, materials: [material])
        body.name = "cup.visual"
        body.position.y = ArenaMetrics.cupHeight / 2

        let rimMesh = ProceduralMeshes.cylinder(height: 0.008, radius: ArenaMetrics.cupTopRadius + 0.003)
        var rimMaterial = SimpleMaterial()
        rimMaterial.color = .init(tint: UIColor(
            red: style.rimRed,
            green: style.rimGreen,
            blue: style.rimBlue,
            alpha: 1
        ))
        rimMaterial.metallic = 0.35
        let rim = ModelEntity(mesh: rimMesh, materials: [rimMaterial])
        rim.position.y = ArenaMetrics.cupHeight
        body.addChild(rim)
        return body
    }

    private static func addDrink(to root: Entity, style: CupStyle, index: Int) {
        let drinks: [UIColor] = [
            UIColor(red: 0.55, green: 0.85, blue: 1.0, alpha: 0.55),
            UIColor(red: 1.0, green: 0.45, blue: 0.28, alpha: 0.50),
            UIColor(red: 0.45, green: 0.95, blue: 0.55, alpha: 0.50),
            UIColor(red: 0.85, green: 0.40, blue: 0.95, alpha: 0.50)
        ]
        var material = SimpleMaterial()
        material.color = .init(tint: drinks[index % drinks.count])
        let drink = ModelEntity(
            mesh: ProceduralMeshes.cylinder(height: 0.035, radius: ArenaMetrics.cupBottomRadius * 0.78),
            materials: [material]
        )
        drink.position.y = 0.028
        drink.name = "cup.drink"
        root.addChild(drink)
    }

    private static func addColliders(to root: Entity, id: UUID) {
        let wallCount = 8
        let radius = (ArenaMetrics.cupTopRadius + ArenaMetrics.cupBottomRadius) * 0.52
        for wall in 0..<wallCount {
            let angle = Float(wall) * (.pi * 2 / Float(wallCount))
            let collider = Entity()
            collider.name = EntityNames.wall(id)
            collider.position = SIMD3(cos(angle) * radius, ArenaMetrics.cupHeight * 0.52, sin(angle) * radius)
            collider.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
            collider.components.set(CollisionComponent(
                shapes: [.generateBox(width: 0.013, height: ArenaMetrics.cupHeight * 0.92, depth: 0.036)],
                mode: .default,
                filter: CollisionGroups.cupFilter
            ))
            collider.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic))
            root.addChild(collider)
        }

        let bottom = Entity()
        bottom.name = EntityNames.wall(id)
        bottom.position.y = 0.008
        bottom.components.set(CollisionComponent(
            shapes: [.generateBox(width: ArenaMetrics.cupBottomRadius * 1.6, height: 0.014, depth: ArenaMetrics.cupBottomRadius * 1.6)],
            mode: .default,
            filter: CollisionGroups.cupFilter
        ))
        bottom.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic))
        root.addChild(bottom)
    }

    private static func addTrigger(to root: Entity, id: UUID) {
        let trigger = Entity()
        trigger.name = EntityNames.trigger(id)
        trigger.position.y = 0.046
        trigger.components.set(CollisionComponent(
            shapes: [.generateBox(width: ArenaMetrics.cupBottomRadius * 1.15, height: 0.055, depth: ArenaMetrics.cupBottomRadius * 1.15)],
            mode: .trigger,
            filter: CollisionGroups.triggerFilter
        ))
        root.addChild(trigger)
    }

    private static func visualColor(style: CupStyle, index: Int) -> UIColor {
        if style.isRainbow {
            let hues: [UIColor] = [
                UIColor(red: 0.95, green: 0.22, blue: 0.32, alpha: 1),
                UIColor(red: 1.0, green: 0.55, blue: 0.12, alpha: 1),
                UIColor(red: 0.98, green: 0.86, blue: 0.18, alpha: 1),
                UIColor(red: 0.20, green: 0.86, blue: 0.42, alpha: 1),
                UIColor(red: 0.18, green: 0.55, blue: 0.98, alpha: 1),
                UIColor(red: 0.62, green: 0.28, blue: 0.96, alpha: 1)
            ]
            return hues[index % hues.count]
        }
        return UIColor(red: style.red, green: style.green, blue: style.blue, alpha: 1)
    }

}
