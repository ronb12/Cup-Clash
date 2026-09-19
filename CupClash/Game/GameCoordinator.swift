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
    private(set) var feedback: String = "Drag to aim, then tap Throw"
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
    private var inputArmTask: Task<Void, Never>?
    private(set) var throwInputArmed = false
    private(set) var cameraReady = true
    private var cameraReadyTask: Task<Void, Never>?

    init(configuration: MatchConfiguration, settings: GameSettings, profile: PlayerProfile) {
        self.configuration = configuration
        self.settings = settings
        self.profile = profile
        rules = MatchRulesEngine(configuration: configuration)
    }

    var state: MatchState { rules.state }
    var canThrow: Bool {
        phase == .aiming && !isPaused && !scene.isBallInFlight && activeHumanCanAct && throwInputArmed && cameraReady
    }

    var activeHumanCanAct: Bool {
        if configuration.mode.usesAI {
            return state.activeSide == .player
        }
        return true
    }

    var currentPlayerName: String {
        state.activeSide == .player ? configuration.playerName : configuration.opponentName
    }

    func start() {
        _ = scene.ensureView()
        guard !configuredScene else {
            if phase == .aiming && !throwInputArmed {
                armThrowInput()
            }
            return
        }
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
        refreshAimPreview()
    }

    func lockAim() {
        throwInput.endDrag()
        guard canThrow else { return }
        refreshAimPreview()
    }

    func releaseThrow() {
        guard canThrow else {
            throwInput.cancel()
            return
        }
        guard let launch = throwInput.commit(minimumPower: scene.physics.minLaunchPower) else {
            scene.updateAim(aim: 0, power: 0, showTrajectory: false, reducedMotion: settings.reducedMotion, snapToCups: false)
            return
        }
        phase = .inFlight
        feedback = "Ball in play"
        AudioManager.shared.play(.throwRelease)
        HapticManager.shared.throwRelease()
        scene.launch(aim: launch.aim, power: launch.power, snapToCups: aimAssistEnabled)
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
        scene.snapToSide(.player)
        cameraReady = true
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
        moveCameraToActiveSide()
        phase = .aiming
        feedback = "\(currentPlayerName)'s throw"
        AudioManager.shared.play(.turn)
        HapticManager.shared.turn()
        armThrowInput()
    }

    private func moveCameraToActiveSide() {
        let side = configuration.mode == .practice ? .player : state.activeSide
        scene.setActiveSide(side)
        cameraReady = !scene.cameraIsTraveling
        cameraReadyTask?.cancel()
        guard !cameraReady else { return }
        cameraReadyTask = Task { [weak self] in
            while let self, self.scene.cameraIsTraveling, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(40))
            }
            guard let self, !Task.isCancelled else { return }
            self.cameraReady = true
        }
        if configuration.mode != .practice {
            AudioManager.shared.play(.turn)
        }
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

    func nudgeAim(_ delta: Float) {
        guard canThrow else { return }
        throwInput.nudgeAim(by: delta)
        refreshAimPreview()
    }

    func throwStraight() {
        guard canThrow else { return }
        let aim = throwInput.aim
        let stored = throwInput.power
        let usedPower: Float
        if stored >= scene.physics.minLaunchPower {
            usedPower = stored
        } else if stored > 0 {
            usedPower = scene.physics.minLaunchPower
        } else {
            feedback = "Pull back to set power"
            return
        }
        throwInput.reset()
        phase = .inFlight
        feedback = "Ball in play"
        AudioManager.shared.play(.throwRelease)
        HapticManager.shared.throwRelease()
        scene.launch(aim: aim, power: usedPower, snapToCups: aimAssistEnabled)
    }

    private func refreshAimPreview() {
        scene.updateAim(
            aim: throwInput.aim,
            power: launchPower(stored: throwInput.power, fallback: 0.55),
            showTrajectory: settings.trajectoryGuideEnabled,
            reducedMotion: settings.reducedMotion,
            snapToCups: aimAssistEnabled,
            onTargetCue: configuration.showsOnTargetCue
        )
    }

    private func launchPower(stored: Float, fallback: Float) -> Float {
        if stored >= scene.physics.minLaunchPower {
            return stored
        }
        return max(fallback, scene.physics.minLaunchPower)
    }

    func teardown() {
        aiTask?.cancel()
        resolveTask?.cancel()
        inputArmTask?.cancel()
        cameraReadyTask?.cancel()
        throwInputArmed = false
        configuredScene = false
        scene.cancelAndTeardown()
    }

    private func armThrowInput() {
        throwInputArmed = false
        inputArmTask?.cancel()
        inputArmTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard let self, !Task.isCancelled else { return }
            self.throwInputArmed = true
        }
    }

    private var aimAssistEnabled: Bool {
        configuration.aimAssistActive
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
        let wasRivalThrow = configuration.mode.usesAI && state.activeSide == .opponent
        let resolution = rules.registerShot(shot, cupID: cupID)
        if let scored = resolution.scoredCupID {
            scene.removeCup(id: scored, animated: true, reducedMotion: settings.reducedMotion)
            AudioManager.shared.play(.made)
            HapticManager.shared.made()
            feedback = "Cup scored"
        } else {
            AudioManager.shared.play(.miss)
            HapticManager.shared.miss()
            feedback = wasRivalThrow ? shot.spokenLabel : (scene.lastMissHint ?? shot.spokenLabel)
        }

        if resolution.matchFinished {
            finishMatch()
            return
        }

        if resolution.shouldOfferPassOverlay {
            resolveTask?.cancel()
            resolveTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, !Task.isCancelled else { return }
                self.phase = .passOverlay
                self.feedback = "Pass the device"
            }
            return
        }

        moveCameraToActiveSide()
        resolveTask?.cancel()
        resolveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(650))
            guard let self, !Task.isCancelled else { return }
            self.phase = .aiming
            self.feedback = "\(self.currentPlayerName)'s throw"
            self.armThrowInput()
            self.maybeStartAITurn()
        }
    }

    private func maybeStartAITurn() {
        guard configuration.mode.usesAI,
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
            if playerWon && configuration.difficulty == .champion && configuration.mode.usesAI {
                GameCenterManager.shared.reportAchievement(id: GameCenterIDs.championDefeated, percent: 100)
            }
            if playerWon && configuration.mode == .dailyChallenge {
                GameCenterManager.shared.reportAchievement(id: GameCenterIDs.dailyChallenger, percent: 100)
            }
            if playerWon && configuration.isSuddenDeath {
                GameCenterManager.shared.reportAchievement(id: GameCenterIDs.clutchFinish, percent: 100)
            }
            if playerWon && configuration.isFinalTournamentRound {
                GameCenterManager.shared.reportAchievement(id: GameCenterIDs.tournamentChampion, percent: 100)
            }
            if ChallengeStore.shared.completedCount >= 4 {
                GameCenterManager.shared.reportAchievement(id: GameCenterIDs.challengeHunter, percent: 100)
            }
        }
        AudioManager.shared.play(playerWon ? .victory : .defeat)
        if playerWon { HapticManager.shared.victory() }
        feedback = playerWon ? "Victory" : "Defeat"
    }
}
