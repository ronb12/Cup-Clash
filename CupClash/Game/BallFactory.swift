import RealityKit
import UIKit

enum BallFactory {
    @MainActor
    static func make(style: BallStyle, physics: PhysicsConfiguration) -> ModelEntity {
        let radius = ArenaMetrics.ballRadius
        let mesh = MeshResource.generateSphere(radius: radius)
        var material = SimpleMaterial()
        material.color = .init(tint: UIColor(
            red: style.red,
            green: style.green,
            blue: style.blue,
            alpha: 1
        ))
        material.metallic = .init(floatLiteral: Float(style.metallic))
        material.roughness = .init(floatLiteral: style.id == "ball.galaxy" ? 0.25 : 0.35)

        let ball = ModelEntity(mesh: mesh, materials: [material])
        ball.name = EntityNames.ball
        ball.collision = CollisionComponent(
            shapes: [.generateSphere(radius: radius)],
            mode: .default,
            filter: CollisionGroups.ballFilter
        )

        var body = PhysicsBodyComponent(
            massProperties: .init(mass: physics.ballMass),
            material: .generate(
                staticFriction: physics.friction,
                dynamicFriction: physics.friction * 0.85,
                restitution: physics.restitution
            ),
            mode: .kinematic
        )
        if #available(iOS 18.0, *) {
            body.linearDamping = physics.linearDamping
            body.angularDamping = physics.angularDamping
            body.isContinuousCollisionDetectionEnabled = true
        }
        ball.components.set(body)
        ball.components.set(PhysicsMotionComponent())
        return ball
    }
}
