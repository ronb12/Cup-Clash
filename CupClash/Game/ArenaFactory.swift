import RealityKit
import UIKit

enum ArenaFactory {
    @MainActor
    static func make(style: ArenaStyle) -> Entity {
        let root = Entity()
        root.name = "arena.root"

        var floorMaterial = SimpleMaterial()
        floorMaterial.color = .init(tint: UIColor(red: style.floorRed, green: style.floorGreen, blue: style.floorBlue, alpha: 1))
        floorMaterial.roughness = 0.9
        let floor = ModelEntity(
            mesh: .generatePlane(width: 14, depth: 14),
            materials: [floorMaterial]
        )
        floor.position.y = 0
        root.addChild(floor)

        var wallMaterial = SimpleMaterial()
        wallMaterial.color = .init(tint: UIColor(red: 0.07, green: 0.06, blue: 0.19, alpha: 1))
        wallMaterial.roughness = 1
        func blended(_ amount: CGFloat) -> UIColor {
            UIColor(
                red: 0.07 + (CGFloat(style.neonRed) - 0.07) * amount,
                green: 0.06 + (CGFloat(style.neonGreen) - 0.06) * amount,
                blue: 0.19 + (CGFloat(style.neonBlue) - 0.19) * amount,
                alpha: 1
            )
        }
        let glow = UnlitMaterial(color: blended(0.55))
        let dimGlow = UnlitMaterial(color: blended(0.25))
        // One wall behind each end of the table so both players get a backdrop.
        for side: Float in [-1, 1] {
            let wall = Entity()
            wall.position = SIMD3(0, 0, side * 3.2)
            if side > 0 { wall.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0]) }
            let panel = ModelEntity(mesh: .generatePlane(width: 14, height: 7), materials: [wallMaterial])
            panel.position = SIMD3(0, 3.2, 0)
            wall.addChild(panel)
            for (y, width, material) in [(0.5 as Float, 2.6 as Float, glow), (0.72, 1.8, dimGlow)] {
                let band = ModelEntity(mesh: .generateBox(width: width, height: 0.035, depth: 0.02), materials: [material])
                band.position = SIMD3(0, y, 0.02)
                wall.addChild(band)
            }
            root.addChild(wall)
        }

        var neon = SimpleMaterial()
        neon.color = .init(tint: UIColor(red: style.neonRed, green: style.neonGreen, blue: style.neonBlue, alpha: 1))
        neon.metallic = 0.2
        for z: Float in [-2.4, 2.4] {
            let strip = ModelEntity(
                mesh: .generateBox(width: 4.6, height: 0.04, depth: 0.04),
                materials: [neon]
            )
            strip.position = SIMD3(0, 1.8, z)
            root.addChild(strip)
        }
        let upright = ModelEntity(
            mesh: .generateBox(width: 0.05, height: 2.2, depth: 0.05),
            materials: [neon]
        )
        upright.position = SIMD3(-2.1, 1.2, -2.4)
        root.addChild(upright)

        var violet = SimpleMaterial()
        violet.color = .init(tint: UIColor(red: 0.62, green: 0.28, blue: 0.98, alpha: 1))
        let accent = ModelEntity(
            mesh: .generateBox(width: 0.05, height: 2.2, depth: 0.05),
            materials: [violet]
        )
        accent.position = SIMD3(2.1, 1.2, -2.4)
        root.addChild(accent)

        return root
    }

    @MainActor
    static func lighting() -> Entity {
        let root = Entity()
        let sun = DirectionalLight()
        sun.light.color = UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1)
        sun.light.intensity = 1400
        sun.shadow = DirectionalLightComponent.Shadow(maximumDistance: 6, depthBias: 1.2)
        sun.look(at: [0, 0.8, 0], from: [1.4, 3.4, 1.6], relativeTo: nil)
        root.addChild(sun)

        let fill = PointLight()
        fill.light.color = UIColor(red: 0.55, green: 0.35, blue: 1.0, alpha: 1)
        fill.light.intensity = 400
        fill.light.attenuationRadius = 6
        fill.position = SIMD3(-1.4, 2.1, -0.4)
        root.addChild(fill)
        return root
    }
}
