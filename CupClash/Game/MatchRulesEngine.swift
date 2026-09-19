import Foundation

struct TurnResolution: Equatable, Sendable {
    var shot: ShotResult
    var scoredCupID: UUID?
    var nextSide: PlayerSide
    var matchFinished: Bool
    var winner: PlayerSide?
    var shouldOfferPassOverlay: Bool
}

struct MatchRulesEngine: Equatable, Sendable {
    var state: MatchState

    init(configuration: MatchConfiguration) {
        let layout = FormationLayout.make(configuration.formation, count: configuration.cupCount, seed: configuration.seed)
        let playerCups = Self.makeCups(owner: .player, layout: layout, nearSide: true)
        let opponentCups = Self.makeCups(owner: .opponent, layout: layout, nearSide: false)
        state = MatchState(
            configuration: configuration,
            cups: playerCups + opponentCups,
            activeSide: .player,
            playerShots: 0,
            opponentShots: 0,
            playerMakes: 0,
            opponentMakes: 0,
            currentMakeStreak: 0,
            bestMakeStreak: 0,
            playerReracksUsed: 0,
            opponentReracksUsed: 0,
            isFinished: false,
            winner: nil,
            lastShot: nil,
            lastScoredCupID: nil,
            turnIndex: 0,
            awaitingPassReady: false
        )
    }

    mutating func registerShot(_ result: ShotResult, cupID: UUID?) -> TurnResolution {
        guard !state.isFinished || state.configuration.mode == .practice else {
            return TurnResolution(
                shot: result,
                scoredCupID: nil,
                nextSide: state.activeSide,
                matchFinished: true,
                winner: state.winner,
                shouldOfferPassOverlay: false
            )
        }

        if state.activeSide == .player {
            state.playerShots += 1
        } else {
            state.opponentShots += 1
        }

        var scoredID: UUID?
        if result == .made, let cupID, let index = state.cups.firstIndex(where: { $0.id == cupID && $0.isActive }) {
            state.cups[index].isActive = false
            scoredID = cupID
            if state.activeSide == .player {
                state.playerMakes += 1
            } else {
                state.opponentMakes += 1
            }
            state.currentMakeStreak += 1
            state.bestMakeStreak = max(state.bestMakeStreak, state.currentMakeStreak)
        } else {
            state.currentMakeStreak = 0
        }

        state.lastShot = result
        state.lastScoredCupID = scoredID

        if state.configuration.mode != .practice {
            let sudden = state.configuration.suddenDeathMakes
            if sudden > 0 {
                if state.playerMakes >= sudden {
                    finish(winner: .player)
                } else if state.opponentMakes >= sudden {
                    finish(winner: .opponent)
                }
            }
            if !state.isFinished {
                if state.playerCupsRemaining == 0 {
                    finish(winner: .player)
                } else if state.opponentCupsRemaining == 0 {
                    finish(winner: .opponent)
                }
            }
        }

        let nextSide: PlayerSide
        if state.isFinished {
            nextSide = state.activeSide
        } else if state.configuration.mode == .practice {
            nextSide = .player
        } else {
            nextSide = state.activeSide.opposite
            state.activeSide = nextSide
            state.turnIndex += 1
        }

        let passOverlay = !state.isFinished && state.configuration.mode == .passAndPlay
        state.awaitingPassReady = passOverlay

        return TurnResolution(
            shot: result,
            scoredCupID: scoredID,
            nextSide: nextSide,
            matchFinished: state.isFinished,
            winner: state.winner,
            shouldOfferPassOverlay: passOverlay
        )
    }

    mutating func acknowledgePassReady() {
        state.awaitingPassReady = false
    }

    mutating func requestRerack(for side: PlayerSide) -> Bool {
        guard state.canRerack(for: side) else { return false }
        let remaining = state.cups.filter { $0.owner == side && $0.isActive }
        let layout = FormationLayout.rerack(remaining: remaining.count)
        let nearSide = side == .player
        let positions = layout.worldPositions(ownerIsNear: nearSide)
        for (offset, cup) in remaining.enumerated() {
            guard let index = state.cups.firstIndex(where: { $0.id == cup.id }) else { continue }
            let position = offset < positions.count ? positions[offset] : cup.worldPosition
            let local = offset < layout.offsets.count ? layout.offsets[offset] : cup.localOffset
            state.cups[index].worldPosition = position
            state.cups[index].localOffset = local
            state.cups[index].rackIndex = offset
        }
        if side == .player {
            state.playerReracksUsed += 1
        } else {
            state.opponentReracksUsed += 1
        }
        return true
    }

    mutating func resetPracticeCups() {
        let layout = FormationLayout.make(
            state.configuration.formation,
            count: state.configuration.cupCount,
            seed: state.configuration.seed
        )
        state.cups = Self.makeCups(owner: .player, layout: layout, nearSide: true)
            + Self.makeCups(owner: .opponent, layout: layout, nearSide: false)
        state.isFinished = false
        state.winner = nil
        state.activeSide = .player
    }

    mutating func applyMovingTarget(phase: Float) {
        guard state.configuration.movingTargets else { return }
        for index in state.cups.indices where state.cups[index].isActive && state.cups[index].owner == .opponent {
            let base = state.cups[index].localOffset
            state.cups[index].worldPosition.x = base.x + sin(phase + Float(index) * 0.7) * 0.08
        }
    }

    static func makeCups(owner: PlayerSide, layout: FormationLayout, nearSide: Bool) -> [CupData] {
        let worlds = layout.worldPositions(ownerIsNear: nearSide)
        return zip(layout.offsets, worlds).enumerated().map { item in
            CupData(
                owner: owner,
                rackIndex: item.offset,
                localOffset: item.element.0,
                worldPosition: item.element.1
            )
        }
    }

    private mutating func finish(winner: PlayerSide) {
        state.isFinished = true
        state.winner = winner
        state.awaitingPassReady = false
    }
}
