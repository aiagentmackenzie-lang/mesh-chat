import Foundation

nonisolated enum StorageKeys: Sendable {
    static let identity = "darknet_identity"
    static let channels = "darknet_channels"
    static let messages = "darknet_messages"
    static let settings = "darknet_settings"
    static let dedupIds = "darknet_dedup_ids"
}

enum StorageService {
    private static let defaults = UserDefaults.standard
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func saveIdentity(_ identity: NodeIdentity) {
        if let data = try? encoder.encode(identity) {
            defaults.set(data, forKey: StorageKeys.identity)
        }
    }

    static func loadIdentity() -> NodeIdentity? {
        guard let data = defaults.data(forKey: StorageKeys.identity) else { return nil }
        return try? decoder.decode(NodeIdentity.self, from: data)
    }

    static func saveChannels(_ channels: [Channel]) {
        if let data = try? encoder.encode(channels) {
            defaults.set(data, forKey: StorageKeys.channels)
        }
    }

    static func loadChannels() -> [Channel] {
        guard let data = defaults.data(forKey: StorageKeys.channels) else { return [] }
        return (try? decoder.decode([Channel].self, from: data)) ?? []
    }

    static func saveMessages(_ messages: [String: [ChatMessage]]) {
        if let data = try? encoder.encode(messages) {
            defaults.set(data, forKey: StorageKeys.messages)
        }
    }

    static func loadMessages() -> [String: [ChatMessage]] {
        guard let data = defaults.data(forKey: StorageKeys.messages) else { return [:] }
        return (try? decoder.decode([String: [ChatMessage]].self, from: data)) ?? [:]
    }

    static func saveSettings(_ settings: AppSettings) {
        if let data = try? encoder.encode(settings) {
            defaults.set(data, forKey: StorageKeys.settings)
        }
    }

    static func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: StorageKeys.settings) else { return AppSettings() }
        return (try? decoder.decode(AppSettings.self, from: data)) ?? AppSettings()
    }

    static func saveDedupIds(_ ids: [String]) {
        if let data = try? encoder.encode(ids) {
            defaults.set(data, forKey: StorageKeys.dedupIds)
        }
    }

    static func loadDedupIds() -> [String] {
        guard let data = defaults.data(forKey: StorageKeys.dedupIds) else { return [] }
        return (try? decoder.decode([String].self, from: data)) ?? []
    }

    static func nukeAll() {
        defaults.removeObject(forKey: StorageKeys.identity)
        defaults.removeObject(forKey: StorageKeys.channels)
        defaults.removeObject(forKey: StorageKeys.messages)
        defaults.removeObject(forKey: StorageKeys.settings)
        defaults.removeObject(forKey: StorageKeys.dedupIds)
    }
}
