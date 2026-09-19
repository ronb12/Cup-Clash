import Combine
import RealityKit
import SwiftUI
import UIKit

@MainActor
final class GameSceneController {
    let physics: PhysicsConfiguration
    private(set) var arView: ARView?
    private let worldAnchor = AnchorEntity(world: .zero)
    private let camera = PerspectiveCamera()
    private let cameraController = GameCameraController()
    private var cupEntities: [UUID: Entity] = [:]
    private var ball: ModelEntity?
    private var trajectoryDots: [ModelEntity] = []
    private var subscriptions: [Cancellable] = []
    private var ballGeneration = 0
    private let evaluator: ShotEvaluator
    private var onShotResolved: ((ShotResult, UUID?) -> Void)?
    private var onCollisionFX: ((CollisionFX) -> Void)?
    private var activeSide: PlayerSide = .player
    private var ballInFlight = false
    private var resolvedThisShot = false
    private var ballStyle = BallStyle.catalog[0]
    private var cupStyle = CupStyle.catalog[0]
    private var movingPhase: Float = 0
    private var movingTargets = false
    private var liveCups: [CupData] = []
    private var firstTableLanding: SIMD3<Float>?
    /// Fixed reach per rack owner, taken from the full rack at setup.
    private var reachByOwner: [PlayerSide: TrajectoryCalculator.ThrowReach] = [:]
    /// Coaching text for the most recent missed shot, if one applies.
    private(set) var lastMissHint: String?

    enum CollisionFX {
        case table
        case rim
    }

    init(physics: PhysicsConfiguration = .playable) {
        self.physics = physics
        evaluator = ShotEvaluator(physics: physics)
    }

    func ensureView() -> ARView {
        if let arView { return arView }
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(UIColor(red: 0.03, green: 0.04, blue: 0.12, alpha: 1))
        view.renderOptions.insert(.disableMotionBlur)
        view.renderOptions.insert(.disablePersonOcclusion)
        view.scene.anchors.append(worldAnchor)
        camera.camera.fieldOfViewInDegrees = 40
        worldAnchor.addChild(camera)
        cameraController.apply(to: camera)
        subscribe(on: view)
        arView = view
        return view
    }

    func configure(
        cups: [CupData],
        ballStyle: BallStyle,
        cupStyle: CupStyle,
        arenaStyle: ArenaStyle,
        reducedMotion: Bool,
        movingTargets: Bool,
        onShotResolved: @escaping (ShotResult, UUID?) -> Void,
        onCollisionFX: @escaping (CollisionFX) -> Void
    ) {
        self.ballStyle = ballStyle
        self.cupStyle = cupStyle
        self.movingTargets = movingTargets
        self.onShotResolved = onShotResolved
        self.onCollisionFX = onCollisionFX
        cameraController.reducedMotion = reducedMotion
        worldAnchor.children.forEach { child in
            if child !== camera {
                child.removeFromParent()
            }
        }
        reachByOwner = [:]
        for owner in [PlayerSide.player, PlayerSide.opponent] {
            let positions = cups.filter { $0.owner == owner }.map(\.worldPosition)
            // The player throws toward -z at the opponent's rack.
            if let reach = TrajectoryCalculator.reach(of: positions, towardNegativeZ: owner == .opponent) {
                reachByOwner[owner] = reach
            }
        }
        trajectoryDots.removeAll()
        cupEntities.removeAll()
        ball = nil

        worldAnchor.addChild(ArenaFactory.make(style: arenaStyle))
        worldAnchor.addChild(ArenaFactory.lighting())
        worldAnchor.addChild(TableFactory.make())
        rebuildCups(cups)
        resetBall(for: .player)
        cameraController.snap(to: .player)
        cameraController.apply(to: camera)
    }

    func rebuildCups(_ cups: [CupData]) {
        liveCups = cups
        cupEntities.values.forEach { $0.removeFromParent() }
        cupEntities = CupRackBuilder.build(cups: cups, style: cupStyle)
        cupEntities.values.forEach { worldAnchor.addChild($0) }
    }

    func updateCupPositions(_ cups: [CupData]) {
        liveCups = cups
        for cup in cups {
            guard let entity = cupEntities[cup.id] else { continue }
            entity.position = cup.worldPosition
            entity.isEnabled = cup.isActive
        }
    }

    func removeCup(id: UUID, animated: Bool, reducedMotion: Bool) {
        if let index = liveCups.firstIndex(where: { $0.id == id }) {
            liveCups[index].isActive = false
        }
        guard let entity = cupEntities[id] else { return }
        celebrate(at: entity.position)
        if !animated || reducedMotion {
            entity.removeFromParent()
            cupEntities[id] = nil
            return
        }
        var transform = entity.transform
        transform.translation.y -= 0.18
        transform.translation.x += 0.12
        transform.scale = SIMD3(repeating: 0.15)
        entity.move(to: transform, relativeTo: entity.parent, duration: 0.38, timingFunction: .easeIn)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) { [weak entity] in
            entity?.removeFromParent()
        }
        cupEntities[id] = nil
    }

    func resetBall(for side: PlayerSide) {
        ball?.removeFromParent()
        let fresh = BallFactory.make(style: ballStyle, physics: physics)
        fresh.position = AIPlayerController.throwOrigin(for: side)
        if var body = fresh.components[PhysicsBodyComponent.self] {
            body.mode = .kinematic
            fresh.components.set(body)
        }
        fresh.components.set(PhysicsMotionComponent())
        worldAnchor.addChild(fresh)
        ball = fresh
        ballInFlight = false
        resolvedThisShot = false
        hideTrajectory()
    }

    func setActiveSide(_ side: PlayerSide) {
        activeSide = side
        cameraController.aiming(for: side)
        resetBall(for: side)
    }

    func snapToSide(_ side: PlayerSide) {
        activeSide = side
        cameraController.snap(to: side)
        resetBall(for: side)
    }

    func updateAim(aim: Float, power: Float, showTrajectory: Bool, reducedMotion: Bool, snapToCups: Bool, onTargetCue: Bool = false) {
        guard let ball, !ballInFlight else { return }
        let origin = AIPlayerController.throwOrigin(for: activeSide)
        ball.position = origin + SIMD3(aim * 0.04, 0, 0)
        guard showTrajectory, power > 0.04 else {
            hideTrajectory()
            return
        }
        let velocity = TrajectoryCalculator.throwVelocity(
            aim: aim,
            power: power,
            from: origin,
            towardNegativeZ: activeSide == .player,
            physics: physics,
            cupTargets: scoringTargets(),
            snapToNearestCup: snapToCups,
            reach: reachByOwner[activeSide.opposite]
        )
        let landing = TrajectoryCalculator.intendedLanding(
            aim: aim,
            power: power,
            from: origin,
            towardNegativeZ: activeSide == .player,
            physics: physics,
            cupTargets: scoringTargets(),
            snapToNearestCup: snapToCups,
            reach: reachByOwner[activeSide.opposite]
        )
        let onTarget = TrajectoryCalculator.isOnTarget(landing: landing, cups: scoringTargets())
        let samples = TrajectoryCalculator.samples(
            origin: origin,
            velocity: velocity,
            gravity: physics.gravity,
            reduced: reducedMotion
        )
        renderTrajectory(samples, power: power, onTarget: onTarget && onTargetCue)
    }

    func launch(aim: Float, power: Float, snapToCups: Bool) {
        guard let ball, !ballInFlight else { return }
        ballGeneration += 1
        evaluator.beginShot(generation: ballGeneration)
        firstTableLanding = nil
        lastMissHint = nil
        let origin = AIPlayerController.throwOrigin(for: activeSide)
        ball.position = origin
        let velocity = TrajectoryCalculator.throwVelocity(
            aim: aim,
            power: max(physics.minLaunchPower, power),
            from: origin,
            towardNegativeZ: activeSide == .player,
            physics: physics,
            cupTargets: scoringTargets(),
            snapToNearestCup: snapToCups,
            reach: reachByOwner[activeSide.opposite]
        )
        applyVelocity(velocity, to: ball)
        ballInFlight = true
        hideTrajectory()
    }

    func launch(planned: PlannedThrow) {
        guard let ball, !ballInFlight else { return }
        ballGeneration += 1
        evaluator.beginShot(generation: ballGeneration)
        firstTableLanding = nil
        lastMissHint = nil
        ball.position = planned.origin
        applyVelocity(planned.velocity, to: ball)
        ballInFlight = true
        hideTrajectory()
    }

    func cancelAndTeardown() {
        subscriptions.removeAll()
        onShotResolved = nil
        onCollisionFX = nil
        ballInFlight = false
    }

    var isBallInFlight: Bool { ballInFlight }
    var cameraIsTraveling: Bool { cameraController.isTraveling }

    private func containedCupID(at position: SIMD3<Float>) -> UUID? {
        let mouth = ArenaMetrics.cupTopRadius * 0.95
        return liveCups.first(where: { cup in
            guard cup.isActive else { return false }
            let dx = position.x - cup.worldPosition.x
            let dz = position.z - cup.worldPosition.z
            let localY = position.y - cup.worldPosition.y
            return hypotf(dx, dz) <= mouth
                && localY > 0.008
                && localY < ArenaMetrics.cupHeight + 0.028
        })?.id
    }

    private func scoringTargets() -> [SIMD3<Float>] {
        liveCups
            .filter { $0.owner == activeSide.opposite && $0.isActive }
            .map(\.worldPosition)
    }

    /// Scales horizontal speed by `physics.launchCompensation` so shots land where the guide (and the AI) aim.
    private func applyVelocity(_ velocity: SIMD3<Float>, to ball: ModelEntity) {
        if var body = ball.components[PhysicsBodyComponent.self] {
            body.mode = .dynamic
            ball.components.set(body)
        }
        let scale = physics.launchCompensation
        let compensated = SIMD3(velocity.x * scale, velocity.y, velocity.z * scale)
        ball.components.set(PhysicsMotionComponent(
            linearVelocity: compensated,
            angularVelocity: SIMD3(velocity.z * 8, 0, -velocity.x * 8)
        ))
    }

    private func subscribe(on view: ARView) {
        let update = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            Self.dispatchMain {
                self?.handleUpdate(event)
            }
        }
        let began = view.scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
            Self.dispatchMain {
                self?.handleCollisionBegan(event)
            }
        }
        let ended = view.scene.subscribe(to: CollisionEvents.Ended.self) { [weak self] event in
            Self.dispatchMain {
                self?.handleCollisionEnded(event)
            }
        }
        subscriptions = [update, began, ended]
    }

    private static func dispatchMain(_ work: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(work)
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private func handleUpdate(_ event: SceneEvents.Update) {
        cameraController.tick(delta: Float(event.deltaTime))
        if ballInFlight, let ball {
            cameraController.follow(ballPosition: ball.position, side: activeSide)
        }
        cameraController.apply(to: camera)

        if movingTargets {
            movingPhase += Float(event.deltaTime)
        }

        guard ballInFlight, !resolvedThisShot, let ball else { return }
        if let cupID = containedCupID(at: ball.position) {
            evaluator.enterTrigger(cupID: cupID)
        }
        let motion = ball.components[PhysicsMotionComponent.self]
        let speed = motion?.linearVelocity.length ?? 0
        let evaluation = evaluator.evaluate(position: ball.position, speed: speed)
        if let result = evaluation.result {
            resolvedThisShot = true
            ballInFlight = false
            lastMissHint = result == .made ? nil : MissHint.describe(
                landing: firstTableLanding ?? ball.position,
                cups: scoringTargets(),
                towardNegativeZ: activeSide == .player
            )
            onShotResolved?(result, evaluation.cupID)
        }
    }

    private func handleCollisionBegan(_ event: CollisionEvents.Began) {
        let names = [event.entityA.name, event.entityB.name]
        if names.contains(EntityNames.table) {
            evaluator.noteTableHit()
            if firstTableLanding == nil { firstTableLanding = ball?.position }
            onCollisionFX?(.table)
        }
        if let wall = names.first(where: { $0.hasPrefix(EntityNames.wallPrefix) }) {
            evaluator.noteRimHit()
            onCollisionFX?(.rim)
            if let id = EntityNames.cupID(from: wall) {
                _ = id
            }
        }
        if let trigger = names.first(where: { $0.hasPrefix(EntityNames.triggerPrefix) }),
           let id = EntityNames.cupID(from: trigger) {
            evaluator.enterTrigger(cupID: id)
        }
    }

    private func handleCollisionEnded(_ event: CollisionEvents.Ended) {
        let names = [event.entityA.name, event.entityB.name]
        if let trigger = names.first(where: { $0.hasPrefix(EntityNames.triggerPrefix) }),
           let id = EntityNames.cupID(from: trigger) {
            evaluator.exitTrigger(cupID: id)
        }
    }

    private func renderTrajectory(_ points: [SIMD3<Float>], power: Float, onTarget: Bool) {
        // Green means the guide is lined up with a cup; otherwise tint by power.
        let tint = onTarget
            ? UIColor(red: 0.25, green: 0.98, blue: 0.55, alpha: 0.95)
            : UIColor(
                red: 0.1 + CGFloat(power) * 0.9,
                green: 0.95 - CGFloat(power) * 0.35,
                blue: 0.98 - CGFloat(power) * 0.6,
                alpha: 0.9
            )
        var material = SimpleMaterial()
        material.color = .init(tint: tint)
        while trajectoryDots.count < points.count {
            let dot = ModelEntity(mesh: .generateSphere(radius: 0.012), materials: [material])
            worldAnchor.addChild(dot)
            trajectoryDots.append(dot)
        }
        for (index, dot) in trajectoryDots.enumerated() {
            if index < points.count {
                dot.isEnabled = true
                dot.position = points[index]
                dot.model?.materials = [material]
            } else {
                dot.isEnabled = false
            }
        }
    }

    private func hideTrajectory() {
        trajectoryDots.forEach { $0.isEnabled = false }
    }

    private func celebrate(at position: SIMD3<Float>) {
        var material = SimpleMaterial()
        material.color = .init(tint: UIColor(red: 0.25, green: 0.98, blue: 0.55, alpha: 1))
        for index in 0..<8 {
            let spark = ModelEntity(mesh: .generateSphere(radius: 0.012), materials: [material])
            spark.name = EntityNames.celebrationPrefix + "\(index)"
            spark.position = position + SIMD3(0, 0.12, 0)
            worldAnchor.addChild(spark)
            let angle = Float(index) / 8 * .pi * 2
            var end = spark.transform
            end.translation += SIMD3(cos(angle) * 0.12, 0.16, sin(angle) * 0.12)
            end.scale = SIMD3(repeating: 0.1)
            spark.move(to: end, relativeTo: worldAnchor, duration: 0.45, timingFunction: .easeOut)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
                spark.removeFromParent()
            }
        }
    }
}
