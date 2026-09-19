import Foundation

struct TournamentSave: Codable, Hashable, Sendable {
    var weekID: String
    var currentRound: Int
    var eliminated: Bool
    var championThisWeek: Bool
    var titles: Int
    var winsThisWeek: Int
}

@MainActor
@Observable
final class TournamentStore {
    static let shared = TournamentStore()

    private let defaults: UserDefaults
    private let key = "cupclash.tournament.state"
    private var state: TournamentSave

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode(TournamentSave.self, from: data) {
            state = saved
        } else {
            state = TournamentSave(
                weekID: TournamentEvent.weekID(),
                currentRound: 1,
                eliminated: false,
                championThisWeek: false,
                titles: 0,
                winsThisWeek: 0
            )
        }
        refreshWeek()
    }

    var titles: Int { state.titles }
    var currentRound: Int { state.currentRound }
    var eliminated: Bool { state.eliminated }
    var championThisWeek: Bool { state.championThisWeek }
    var winsThisWeek: Int { state.winsThisWeek }
    var weekID: String { state.weekID }

    var isComplete: Bool { state.currentRound >= 4 }
    var weeklyScore: Int { winsThisWeek * 10 + (championThisWeek ? 50 : 0) }

    func refreshWeek(date: Date = Date(), calendar: Calendar = .current) {
        let week = TournamentEvent.weekID(for: date, calendar: calendar)
        guard state.weekID != week else { return }
        state.weekID = week
        state.currentRound = 1
        state.eliminated = false
        state.championThisWeek = false
        state.winsThisWeek = 0
        persist()
    }

    func status(for round: Int) -> TournamentRoundStatus {
        if state.eliminated {
            if round < state.currentRound { return .won }
            if round == state.currentRound { return .lost }
            return .locked
        }
        if state.currentRound >= 4 { return .won }
        if round < state.currentRound { return .won }
        if round == state.currentRound { return .current }
        return .locked
    }

    func playableConfiguration(playerName: String, aimAssistance: Bool) -> MatchConfiguration? {
        refreshWeek()
        guard !state.eliminated, state.currentRound <= 3 else { return nil }
        return TournamentEvent.current().configuration(
            round: max(state.currentRound, 1),
            playerName: playerName,
            aimAssistance: aimAssistance
        )
    }

    func retryWeek() {
        refreshWeek()
        state.eliminated = false
        state.currentRound = 1
        persist()
    }

    func record(result: MatchResult) {
        guard result.configuration.mode == .tournament else { return }
        refreshWeek()
        if !result.configuration.eventID.isEmpty, result.configuration.eventID != state.weekID {
            return
        }
        if result.playerWon {
            state.winsThisWeek += 1
            if result.configuration.eventRound >= 3 {
                if !state.championThisWeek {
                    state.championThisWeek = true
                    state.titles += 1
                }
                state.currentRound = 4
                state.eliminated = false
            } else {
                state.currentRound = max(state.currentRound, result.configuration.eventRound + 1)
            }
        } else if result.winner != nil {
            state.eliminated = true
        }
        persist()
    }

    func reset() {
        state = TournamentSave(
            weekID: TournamentEvent.weekID(),
            currentRound: 1,
            eliminated: false,
            championThisWeek: false,
            titles: 0,
            winsThisWeek: 0
        )
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: key)
        }
    }
}
