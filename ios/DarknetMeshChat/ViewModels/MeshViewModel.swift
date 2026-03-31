import Foundation
import SwiftUI

@Observable
class MeshViewModel {
    var identity: NodeIdentity?
    var nearbyNodes: [MeshNode] = []
    var channels: [Channel] = []
    var messages: [String: [ChatMessage]] = [:]
    var settings: AppSettings = AppSettings()
    var meshStatus: MeshStatus = .offline
    var dedupIds: [String] = []

    var bleService = BLEMeshService()

    var hasIdentity: Bool { identity != nil }

    var accentColor: Color {
        Color(hex: settings.accentColorChoice.hex)
    }

    func hydrate() {
        identity = StorageService.loadIdentity()
        let savedChannels = StorageService.loadChannels()
        channels = savedChannels.isEmpty ? Channel.defaultPublicChannels : savedChannels
        messages = StorageService.loadMessages()
        settings = StorageService.loadSettings()
        dedupIds = StorageService.loadDedupIds()
    }

    func createIdentity(alias: String, color: NodeColor) {
        let node = NodeIdentity.generate(alias: alias, color: color)
        identity = node
        StorageService.saveIdentity(node)
    }

    func initializeBLE() {
        bleService.channelKeyProvider = { [weak self] channelName in
            self?.sharedKey(forRemoteChannelName: channelName)
        }
        bleService.onMessageReceived = { [weak self] packet, decryptedContent in
            self?.handleReceivedPacket(packet, decryptedContent: decryptedContent)
        }
        bleService.initialize()
    }

    func startScanning() {
        bleService.startScanning()
    }

    func stopScanning() {
        bleService.stopScanning()
    }

    func sendMessage(content: String, channelId: String) {
        guard let identity else { return }
        guard let channel = channels.first(where: { $0.id == channelId }) else { return }
        guard let channelKey = sharedKey(for: channel) else { return }

        guard let encrypted = CryptoService.encrypt(content, key: channelKey) else { return }

        let message = ChatMessage(
            id: UUID().uuidString,
            fromAlias: identity.alias,
            fromKey: identity.publicKey,
            toTarget: channel.displayName,
            channelId: channelId,
            content: content,
            hops: 0,
            maxHops: settings.hopLimit,
            timestamp: Date(),
            ttl: channel.ttl.seconds.map { Date().addingTimeInterval($0) },
            type: .msg,
            deliveryStatus: .sent
        )

        var channelMessages = messages[channelId] ?? []
        channelMessages.append(message)
        messages[channelId] = channelMessages

        if let idx = channels.firstIndex(where: { $0.id == channelId }) {
            channels[idx].lastActivity = Date()
            channels[idx].lastMessagePreview = content
        }

        let packet = MeshPacket(
            v: 1,
            id: message.id,
            from: identity.alias,
            fromKey: identity.publicKey,
            to: channel.displayName,
            channel: channel.displayName,
            payload: encrypted,
            hops: 0,
            maxHops: settings.hopLimit,
            ts: Int64(Date().timeIntervalSince1970 * 1000),
            ttl: message.ttl.map { Int64($0.timeIntervalSince1970 * 1000) },
            type: "msg"
        )
        bleService.sendMessage(packet)

        persistState()
    }

    func createChannel(name: String, type: ChannelType, password: String?, ttl: MessageTTL) {
        let normalizedName = name.uppercased()
        let sharedKey = type == .publicMesh
            ? CryptoService.derivedChannelKey(name: normalizedName, password: password)
            : CryptoService.generateSymmetricKey()
        let channel = Channel(
            id: "ch-\(UUID().uuidString.prefix(8))",
            name: normalizedName,
            type: type,
            members: [identity?.alias ?? ""],
            sharedKey: sharedKey,
            password: password?.isEmpty == true ? nil : password,
            ttl: ttl,
            lastActivity: Date(),
            unreadCount: 0,
            createdAt: Date()
        )
        channels.append(channel)
        persistState()
    }

    func openPrivateChannel(with node: MeshNode) {
        if channels.contains(where: { $0.name == node.alias && $0.type == .private1to1 }) { return }
        let channel = Channel(
            id: "ch-\(UUID().uuidString.prefix(8))",
            name: node.alias,
            type: .private1to1,
            members: [identity?.alias ?? "", node.alias],
            sharedKey: CryptoService.generateSymmetricKey(),
            ttl: .infinite,
            lastActivity: Date(),
            unreadCount: 0,
            createdAt: Date()
        )
        channels.append(channel)
        persistState()
    }

    func leaveChannel(_ channelId: String) {
        channels.removeAll { $0.id == channelId }
        messages.removeValue(forKey: channelId)
        persistState()
    }

    func nukeAllChats() {
        messages = [:]
        persistState()
    }

    func resetIdentity() {
        StorageService.nukeAll()
        identity = nil
        channels = Channel.defaultPublicChannels
        messages = [:]
        settings = AppSettings()
        dedupIds = []
    }

    func emergencyWipe() {
        StorageService.nukeAll()
        identity = nil
        channels = []
        messages = [:]
        settings = AppSettings()
        dedupIds = []
    }

    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        StorageService.saveSettings(newSettings)
    }

    func updateIdentityAlias(_ alias: String) {
        identity?.alias = alias.uppercased()
        if let identity {
            StorageService.saveIdentity(identity)
        }
    }

    func rotateKeys() {
        guard var id = identity else { return }
        let newKeyPair = CryptoService.generateKeyPair()
        id = NodeIdentity(
            id: id.id,
            alias: id.alias,
            color: id.color,
            publicKey: newKeyPair.publicKey,
            privateKey: newKeyPair.privateKey,
            createdAt: id.createdAt
        )
        identity = id
        StorageService.saveIdentity(id)
    }

    func persistState() {
        StorageService.saveChannels(channels)
        StorageService.saveMessages(messages)
    }

    private func sharedKey(for channel: Channel) -> String? {
        switch channel.type {
        case .publicMesh:
            return CryptoService.derivedChannelKey(name: channel.name, password: channel.password)
        case .private1to1, .group:
            return channel.sharedKey
        }
    }

    private func sharedKey(forRemoteChannelName channelName: String) -> String? {
        let normalizedRemoteName = channelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPublicName = normalizedRemoteName.hasPrefix("#")
            ? String(normalizedRemoteName.dropFirst()).uppercased()
            : normalizedRemoteName.uppercased()

        if let channel = channels.first(where: {
            $0.displayName.caseInsensitiveCompare(normalizedRemoteName) == .orderedSame ||
            $0.name.caseInsensitiveCompare(normalizedPublicName) == .orderedSame
        }) {
            return sharedKey(for: channel)
        }

        if normalizedRemoteName.hasPrefix("#") {
            return CryptoService.derivedChannelKey(name: normalizedPublicName, password: nil)
        }

        return nil
    }

    private func handleReceivedPacket(_ packet: MeshPacket, decryptedContent: String) {
        guard !dedupIds.contains(packet.id) else { return }

        dedupIds.append(packet.id)
        if dedupIds.count > 500 {
            dedupIds.removeFirst(dedupIds.count - 500)
        }
        StorageService.saveDedupIds(dedupIds)

        let channelId = ensureChannelExists(for: packet)
        let message = ChatMessage(
            id: packet.id,
            fromAlias: packet.from,
            fromKey: packet.fromKey,
            toTarget: packet.to,
            channelId: channelId,
            content: decryptedContent,
            hops: packet.hops,
            maxHops: packet.maxHops,
            timestamp: Date(timeIntervalSince1970: TimeInterval(packet.ts) / 1000),
            ttl: packet.ttl.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) },
            type: MessageType(rawValue: packet.type) ?? .msg,
            deliveryStatus: .delivered
        )

        var channelMessages = messages[channelId] ?? []
        channelMessages.append(message)
        messages[channelId] = channelMessages

        if let idx = channels.firstIndex(where: { $0.id == channelId }) {
            channels[idx].lastActivity = message.timestamp
            channels[idx].lastMessagePreview = decryptedContent
            channels[idx].unreadCount += 1
        }

        persistState()
    }

    private func ensureChannelExists(for packet: MeshPacket) -> String {
        if let existingChannel = channels.first(where: {
            $0.displayName.caseInsensitiveCompare(packet.channel) == .orderedSame ||
            $0.name.caseInsensitiveCompare(packet.channel.replacingOccurrences(of: "#", with: "")) == .orderedSame
        }) {
            return existingChannel.id
        }

        let channelName = packet.channel.hasPrefix("#")
            ? String(packet.channel.dropFirst()).uppercased()
            : packet.channel.uppercased()
        let channelType: ChannelType = packet.channel.hasPrefix("#") ? .publicMesh : .group
        let sharedKey = channelType == .publicMesh
            ? CryptoService.derivedChannelKey(name: channelName, password: nil)
            : CryptoService.generateSymmetricKey()

        let channel = Channel(
            id: "ch-\(UUID().uuidString.prefix(8))",
            name: channelName,
            type: channelType,
            members: [packet.from],
            sharedKey: sharedKey,
            ttl: packet.ttl == nil ? .infinite : .oneDay,
            lastActivity: Date(),
            unreadCount: 1,
            createdAt: Date()
        )
        channels.append(channel)
        return channel.id
    }
}
