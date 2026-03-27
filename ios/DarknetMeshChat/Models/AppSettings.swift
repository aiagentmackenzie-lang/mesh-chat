import Foundation

nonisolated struct AppSettings: Codable, Sendable {
    var encryptionProtocol: EncryptionProtocolType = .aes256
    var keyRotation: KeyRotation = .never
    var hopLimit: Int = 3
    var scanInterval: ScanInterval = .balanced
    var broadcastPower: BroadcastPower = .medium
    var backgroundScanning: Bool = true
    var defaultTTL: MessageTTL = .infinite
    var readReceipts: Bool = true
    var typingIndicators: Bool = true
    var messageHistoryLimit: HistoryLimit = .fiveHundred
    var accentColorChoice: AccentChoice = .green
    var matrixRain: Bool = false
}

nonisolated enum EncryptionProtocolType: String, Codable, Sendable, CaseIterable {
    case aes256 = "AES-256"
    case x25519Aes = "X25519+AES-256"
}

nonisolated enum KeyRotation: String, Codable, Sendable, CaseIterable {
    case never = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
}

nonisolated enum ScanInterval: String, Codable, Sendable, CaseIterable {
    case aggressive = "Aggressive (2s)"
    case balanced = "Balanced (5s)"
    case batterySaver = "Battery Saver (15s)"

    var seconds: TimeInterval {
        switch self {
        case .aggressive: 2
        case .balanced: 5
        case .batterySaver: 15
        }
    }
}

nonisolated enum BroadcastPower: String, Codable, Sendable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

nonisolated enum HistoryLimit: Int, Codable, Sendable, CaseIterable {
    case oneHundred = 100
    case fiveHundred = 500
    case oneThousand = 1000
    case unlimited = -1

    var displayName: String {
        switch self {
        case .oneHundred: "100"
        case .fiveHundred: "500"
        case .oneThousand: "1000"
        case .unlimited: "Unlimited"
        }
    }
}

nonisolated enum AccentChoice: String, Codable, Sendable, CaseIterable {
    case green, blue, red, orange

    var hex: UInt {
        switch self {
        case .green: 0x00FF88
        case .blue: 0x00AAFF
        case .red: 0xFF0033
        case .orange: 0xFF8800
        }
    }
}
