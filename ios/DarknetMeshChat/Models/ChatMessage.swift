import Foundation

nonisolated struct ChatMessage: Codable, Sendable, Identifiable {
    let id: String
    let fromAlias: String
    let fromKey: String
    let toTarget: String
    let channelId: String
    let content: String
    let hops: Int
    let maxHops: Int
    let timestamp: Date
    let ttl: Date?
    let type: MessageType
    var deliveryStatus: DeliveryStatus

    var isSystem: Bool {
        type == .join || type == .leave || type == .ping
    }

    var selfDestructsIn: String? {
        guard let ttl else { return nil }
        let remaining = ttl.timeIntervalSince(Date())
        guard remaining > 0 else { return nil }
        if remaining < 60 { return "\(Int(remaining))s" }
        if remaining < 3600 { return "\(Int(remaining / 60))m" }
        return "\(Int(remaining / 3600))h"
    }
}

nonisolated enum MessageType: String, Codable, Sendable {
    case msg, typing, join, leave, ping
}

nonisolated enum DeliveryStatus: String, Codable, Sendable {
    case queued, sent, delivered

    var symbol: String {
        switch self {
        case .queued: "●"
        case .sent: "✓"
        case .delivered: "✓✓"
        }
    }
}

nonisolated struct MeshPacket: Codable, Sendable {
    let v: Int
    let id: String
    let from: String
    let fromKey: String
    let to: String
    let channel: String
    let payload: String
    let hops: Int
    let maxHops: Int
    let ts: Int64
    let ttl: Int64?
    let type: String
}
