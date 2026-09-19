import Foundation

@MainActor
@Observable
final class ChallengeStore {
    static let shared = ChallengeStore()

    private let defaults: UserDefaults
    private let key = "cupclash.challenges.completed"
    private(set) var completed: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completed = Set(defaults.stringArray(forKey: key) ?? [])
    }

    func completedIDs() -> Set<String> { completed }

    var completedCount: Int { completed.count }

    func isComplete(_ id: String) -> Bool {
        completed.contains(id)
    }

    @discardableResult
    func record(result: MatchResult) -> [ChallengeDefinition] {
        var unlocked: [ChallengeDefinition] = []
        for challenge in ChallengeDefinition.all where !completed.contains(challenge.id) {
            if challenge.isSatisfied(by: result) {
                completed.insert(challenge.id)
                unlocked.append(challenge)
            }
        }
        if !unlocked.isEmpty {
            defaults.set(Array(completed).sorted(), forKey: key)
        }
        return unlocked
    }

    func reset() {
        completed = []
        defaults.removeObject(forKey: key)
    }
}
