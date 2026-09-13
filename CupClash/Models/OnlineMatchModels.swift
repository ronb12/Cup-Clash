import Foundation

/// Payload reserved for a future real-time Game Center match.
struct OnlineShotPayload: Codable, Hashable, Sendable {
    var aimX: Float
    var power: Float
    var arc: Float
    var seed: UInt64
    var timestamp: Date
}

enum OnlineMatchMessageKind: String, Codable, Sendable {
    case ready
    case shot
    case rerack
    case pause
    case forfeit
}

struct OnlineMatchMessage: Codable, Hashable, Sendable {
    var kind: OnlineMatchMessageKind
    var senderName: String
    var shot: OnlineShotPayload?
    var sentAt: Date
}

/// Prepared for later Game Center real-time multiplayer. Local play does not use this.
@MainActor
protocol OnlineMatchServicing: AnyObject {
    var isConnected: Bool { get }
    func hostMatch(configuration: MatchConfiguration) async throws
    func joinMatch(inviteID: String) async throws
    func send(_ message: OnlineMatchMessage)
    func disconnect()
}
