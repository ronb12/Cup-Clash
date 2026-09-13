import RealityKit
import UIKit

enum TableFactory {
    @MainActor
    static func make() -> Entity {
        let root = Entity()
        root.name = "table.root"

        let width = ArenaMetrics.tableWidth
        let length = ArenaMetrics.tableLength
        let thickness = ArenaMetrics.tableThickness
        let surfaceY = ArenaMetrics.tableSurfaceY

        var felt = SimpleMaterial()
        felt.color = .init(tint: UIColor(red: 0.07, green: 0.18, blue: 0.28, alpha: 1))
        felt.roughness = 0.75

        let surface = ModelEntity(
            mesh: .generateBox(width: width, height: thickness, depth: length, cornerRadius: 0.02),
            materials: [felt]
        )
        surface.name = EntityNames.table
        surface.position = SIMD3(0, surfaceY - thickness / 2, 0)
        surface.collision = CollisionComponent(
            shapes: [.generateBox(size: [width, thickness + 0.03, length])],
            mode: .default,
            filter: CollisionGroups.tableFilter
        )
        var tableBody = PhysicsBodyComponent(massProperties: .default, material: .generate(staticFriction: 0.45, dynamicFriction: 0.38, restitution: 0.22), mode: .static)
        tableBody.mode = .static
        surface.components.set(tableBody)
        root.addChild(surface)

        var trimMaterial = SimpleMaterial()
        trimMaterial.color = .init(tint: UIColor(red: 0.0, green: 0.90, blue: 0.98, alpha: 1))
        trimMaterial.metallic = 0.55
        let trim = ModelEntity(
            mesh: .generateBox(width: width + 0.04, height: 0.03, depth: length + 0.04, cornerRadius: 0.018),
            materials: [trimMaterial]
        )
        trim.name = EntityNames.tableTrim
        trim.position = SIMD3(0, surfaceY - thickness - 0.01, 0)
        root.addChild(trim)

        var lineMaterial = SimpleMaterial()
        lineMaterial.color = .init(tint: UIColor(red: 0.85, green: 0.90, blue: 1.0, alpha: 0.9))
        let center = ModelEntity(
            mesh: .generateBox(width: width * 0.92, height: 0.004, depth: 0.018),
            materials: [lineMaterial]
        )
        center.position = SIMD3(0, surfaceY + 0.002, 0)
        root.addChild(center)

        var logoMaterial = SimpleMaterial()
        logoMaterial.color = .init(tint: UIColor(red: 0.62, green: 0.28, blue: 0.98, alpha: 0.85))
        let logo = ModelEntity(
            mesh: ProceduralMeshes.cylinder(height: 0.003, radius: 0.07),
            materials: [logoMaterial]
        )
        logo.position = SIMD3(0, surfaceY + 0.003, 0)
        root.addChild(logo)

        var railMaterial = SimpleMaterial()
        railMaterial.color = .init(tint: UIColor(red: 0.16, green: 0.18, blue: 0.28, alpha: 1))
        for xSign: Float in [-1, 1] {
            let rail = ModelEntity(
                mesh: .generateBox(width: 0.04, height: 0.72, depth: 0.04),
                materials: [railMaterial]
            )
            rail.position = SIMD3(xSign * (width / 2 - 0.03), 0.36, length / 2 - 0.04)
            root.addChild(rail)
            let rail2 = ModelEntity(
                mesh: .generateBox(width: 0.04, height: 0.72, depth: 0.04),
                materials: [railMaterial]
            )
            rail2.position = SIMD3(xSign * (width / 2 - 0.03), 0.36, -length / 2 + 0.04)
            root.addChild(rail2)
        }

        return root
    }
}
