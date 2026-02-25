import Foundation

nonisolated struct Channel: Codable, Sendable, Identifiable, Hashable {
    let id: String
    var name: String
    var type: ChannelType
    var members: [String]
    var sharedKey: String
    var password: String?
    var ttl: MessageTTL
    var lastActivity: Date
    var unreadCount: Int
    var lastMessagePreview: String?
    let createdAt: Date

    var displayName: String {
        switch type {
        case .publicMesh: "#\(name.lowercased())"
        case .private1to1: name
        case .group: name
        }
    }

    var isProtected: Bool { password != nil }
}

nonisolated enum ChannelType: String, Codable, Sendable {
    case publicMesh = "PUBLIC"
    case private1to1 = "PRIVATE"
    case group = "GROUP"
}

nonisolated enum MessageTTL: String, Codable, Sendable, CaseIterable {
    case infinite = "infinite"
    case oneHour = "1h"
    case oneDay = "24h"
    case oneWeek = "7d"

    var displayName: String {
        switch self {
        case .infinite: "Infinite"
        case .oneHour: "1 Hour"
        case .oneDay: "24 Hours"
        case .oneWeek: "7 Days"
        }
    }

    var seconds: TimeInterval? {
        switch self {
        case .infinite: nil
        case .oneHour: 3600
        case .oneDay: 86400
        case .oneWeek: 604800
        }
    }
}

extension Channel {
    static let defaultPublicChannels: [Channel] = [
        Channel(
            id: "ch-void", name: "void", type: .publicMesh,
            members: [], sharedKey: CryptoService.generateSymmetricKey(),
            ttl: .infinite, lastActivity: Date(), unreadCount: 0,
            createdAt: Date()
        ),
        Channel(
            id: "ch-mesh", name: "mesh", type: .publicMesh,
            members: [], sharedKey: CryptoService.generateSymmetricKey(),
            ttl: .infinite, lastActivity: Date(), unreadCount: 0,
            createdAt: Date()
        ),
        Channel(
            id: "ch-null", name: "null", type: .publicMesh,
            members: [], sharedKey: CryptoService.generateSymmetricKey(),
            ttl: .infinite, lastActivity: Date(), unreadCount: 0,
            createdAt: Date()
        ),
    ]
}
