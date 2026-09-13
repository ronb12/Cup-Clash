import Foundation
import Observation
import simd

enum GamePhase: Equatable, Sendable {
    case loading
    case aiming
    case inFlight
    case resolving
    case passOverlay
    case finished
}

@MainActor
@Observable
final class GameCoordinator {
    let configuration: MatchConfiguration
    let scene = GameSceneController()
    let throwInput = ThrowInputController()
    private(set) var rules: MatchRulesEngine
    private(set) var phase: GamePhase = .loading
    private(set) var feedback: String = "Drag back to throw"
    private(set) var isPaused = false
    private(set) var result: MatchResult?
    private(set) var showSettings = false
    private(set) var showHelp = false
    private(set) var confirmAbandon = false

    var settings: GameSettings
    var profile: PlayerProfile

    private var aiTask: Task<Void, Never>?
    private var resolveTask: Task<Void, Never>?
    private var rewardsApplied = false
    private var configuredScene = false
    private var inputEnabledAt = Date.distantPast

    init(configuration: MatchConfiguration, settings: GameSettings, profile: PlayerProfile) {
        self.configuration = configuration
        self.settings = settings
        self.profile = profile
        rules = MatchRulesEngine(configuration: configuration)
    }

    var state: MatchState { rules.state }
    var canThrow: Bool {
        phase == .aiming && !isPaused && !scene.isBallInFlight && activeHumanCanAct && Date() >= inputEnabledAt
    }

    var activeHumanCanAct: Bool {
        if configuration.mode == .quickMatch {
            return state.activeSide == .player
        }
        return true
    }

    var currentPlayerName: String {
        state.activeSide == .player ? configuration.playerName : configuration.opponentName
    }

    func start() {
        guard !configuredScene else { return }
        configuredScene = true
        scene.configure(
            cups: state.cups,
            ballStyle: BallStyle.style(id: profile.selectedBallStyleID),
            cupStyle: CupStyle.style(id: profile.selectedCupStyleID),
            arenaStyle: ArenaStyle.style(id: profile.selectedArenaID),
            reducedMotion: settings.reducedMotion,
            movingTargets: configuration.movingTargets,
            onShotResolved: { [weak self] result, cupID in
                self?.handleResolvedShot(result, cupID: cupID)
            },
            onCollisionFX: { [weak self] fx in
                self?.handleCollision(fx)
            }
        )
        phase = .aiming
        feedback = "Your throw"
        armThrowInput()
        maybeStartAITurn()
    }

    func updateAim(translation: CGSize) {
        guard canThrow else { return }
        if !throwInput.isAiming {
            throwInput.begin()
        }
        throwInput.update(
            translation: translation,
            sensitivity: settings.clampedSensitivity,
            leftHanded: settings.leftHandedControls
        )
        scene.updateAim(
            aim: throwInput.aim,
            power: throwInput.power,
            showTrajectory: settings.trajectoryGuideEnabled,
            reducedMotion: settings.reducedMotion,
            aimAssistX: assistedCupX()
        )
    }

    func releaseThrow() {
        guard canThrow else {
            throwInput.cancel()
            return
        }
        guard let launch = throwInput.commit(minimumPower: scene.physics.minLaunchPower) else {
            scene.updateAim(aim: 0, power: 0, showTrajectory: false, reducedMotion: settings.reducedMotion, aimAssistX: nil)
            return
        }
        phase = .inFlight
        feedback = "Ball in play"
        AudioManager.shared.play(.throwRelease)
        HapticManager.shared.throwRelease()
        scene.launch(aim: launch.aim, power: launch.power, aimAssistX: assistedCupX())
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            aiTask?.cancel()
        } else if phase == .aiming {
            maybeStartAITurn()
        }
    }

    func resume() {
        isPaused = false
        confirmAbandon = false
        if phase == .aiming {
            maybeStartAITurn()
        }
    }

    func requestAbandon() {
        confirmAbandon = true
    }

    func restart() {
        aiTask?.cancel()
        resolveTask?.cancel()
        rules = MatchRulesEngine(configuration: configuration)
        result = nil
        rewardsApplied = false
        isPaused = false
        confirmAbandon = false
        phase = .aiming
        feedback = "New match"
        scene.rebuildCups(state.cups)
        scene.setActiveSide(.player)
        armThrowInput()
        maybeStartAITurn()
    }

    func requestRerack() {
        let side = configuration.mode == .passAndPlay ? state.activeSide : .player
        guard rules.requestRerack(for: side) else { return }
        scene.updateCupPositions(state.cups)
        feedback = "Re-rack complete"
        AudioManager.shared.play(.turn)
    }

    func acknowledgePass() {
        rules.acknowledgePassReady()
        scene.setActiveSide(state.activeSide)
        phase = .aiming
        feedback = "\(currentPlayerName)'s throw"
        AudioManager.shared.play(.turn)
        HapticManager.shared.turn()
        armThrowInput()
    }

    func resetPracticeBall() {
        guard configuration.mode == .practice else { return }
        scene.resetBall(for: .player)
        phase = .aiming
        feedback = "Ball reset"
    }

    func resetPracticeCups() {
        guard configuration.mode == .practice else { return }
        rules.resetPracticeCups()
        scene.rebuildCups(state.cups)
        scene.resetBall(for: .player)
        phase = .aiming
        feedback = "Cups reset"
    }

    func teardown() {
        aiTask?.cancel()
        resolveTask?.cancel()
        scene.cancelAndTeardown()
    }

    private func armThrowInput() {
        inputEnabledAt = Date().addingTimeInterval(0.4)
    }

    private func assistedCupX() -> Float? {
        guard settings.aimAssistanceEnabled || configuration.aimAssistance else { return nil }
        let targets = state.cups.filter { $0.owner == state.activeSide.opposite && $0.isActive }
        return targets.min(by: { abs($0.worldPosition.x) < abs($1.worldPosition.x) })?.worldPosition.x
    }

    private func handleCollision(_ fx: GameSceneController.CollisionFX) {
        switch fx {
        case .table:
            AudioManager.shared.play(.tableBounce)
            HapticManager.shared.table()
        case .rim:
            AudioManager.shared.play(.rimHit)
            HapticManager.shared.rim()
        }
    }

    private func handleResolvedShot(_ shot: ShotResult, cupID: UUID?) {
        phase = .resolving
        let resolution = rules.registerShot(shot, cupID: cupID)
        if let scored = resolution.scoredCupID {
            scene.removeCup(id: scored, animated: true, reducedMotion: settings.reducedMotion)
            AudioManager.shared.play(.made)
            HapticManager.shared.made()
            feedback = "Cup scored"
        } else {
            AudioManager.shared.play(.miss)
            HapticManager.shared.miss()
            feedback = shot.spokenLabel
        }

        if resolution.matchFinished {
            finishMatch()
            return
        }

        resolveTask?.cancel()
        resolveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(650))
            guard let self, !Task.isCancelled else { return }
            if resolution.shouldOfferPassOverlay {
                self.phase = .passOverlay
                self.feedback = "Pass the device"
                return
            }
            self.scene.setActiveSide(self.state.activeSide)
            self.phase = .aiming
            self.feedback = "\(self.currentPlayerName)'s throw"
            self.armThrowInput()
            self.maybeStartAITurn()
        }
    }

    private func maybeStartAITurn() {
        guard configuration.mode == .quickMatch,
              state.activeSide == .opponent,
              !state.isFinished,
              !isPaused else { return }
        aiTask?.cancel()
        aiTask = Task { [weak self] in
            guard let self else { return }
            guard let plan = AIPlayerController.planThrow(
                difficulty: self.configuration.difficulty,
                cups: self.state.cups,
                throwingSide: .opponent
            ) else { return }
            try? await Task.sleep(for: .seconds(plan.thinkTime))
            guard !Task.isCancelled, !self.isPaused, self.phase == .aiming else { return }
            self.phase = .inFlight
            self.feedback = "Rival is throwing"
            AudioManager.shared.play(.throwRelease)
            self.scene.launch(planned: plan)
        }
    }

    private func finishMatch() {
        phase = .finished
        let playerWon = state.winner == .player
        let already = profile.lastRewardMatchID
        var rewards = RewardCalculator.breakdown(
            configuration: configuration,
            playerWon: playerWon,
            playerMakes: state.playerMakes,
            bestStreak: state.bestMakeStreak,
            alreadyGranted: false
        )
        rewards = RewardCalculator.applyingLevelUps(to: rewards, startingTotalXP: profile.totalXP)
        let matchResult = MatchResult(
            id: UUID(),
            configuration: configuration,
            winner: state.winner,
            playerWon: playerWon,
            playerCupsRemaining: state.playerCupsRemaining,
            opponentCupsRemaining: state.opponentCupsRemaining,
            playerShots: state.playerShots,
            playerMakes: state.playerMakes,
            opponentShots: state.opponentShots,
            opponentMakes: state.opponentMakes,
            bestStreak: state.bestMakeStreak,
            perfectGame: state.playerMakes == configuration.cupCount.rawValue && state.playerShots == state.playerMakes,
            rewards: rewards,
            startingTotalXP: profile.totalXP,
            endingTotalXP: profile.totalXP + rewards.totalXP,
            startingLevel: profile.currentLevel,
            endingLevel: ProgressionMath.level(forTotalXP: profile.totalXP + rewards.totalXP)
        )
        result = matchResult
        if !rewardsApplied && already != matchResult.id.uuidString {
            PersistenceManager.shared.apply(result: matchResult)
            rewardsApplied = true
            GameCenterManager.shared.sync(profile: PersistenceManager.shared.profile())
            if matchResult.perfectGame {
                GameCenterManager.shared.reportAchievement(id: GameCenterIDs.perfectMatch, percent: 100)
            }
            if playerWon && configuration.difficulty == .champion && configuration.mode == .quickMatch {
                GameCenterManager.shared.reportAchievement(id: GameCenterIDs.championDefeated, percent: 100)
            }
        }
        AudioManager.shared.play(playerWon ? .victory : .defeat)
        if playerWon { HapticManager.shared.victory() }
        feedback = playerWon ? "Victory" : "Defeat"
    }
}
