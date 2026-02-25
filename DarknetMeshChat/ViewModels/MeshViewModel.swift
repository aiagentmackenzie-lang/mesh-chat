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

        let encrypted = CryptoService.encrypt(content, key: channel.sharedKey) ?? content

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
        simulateReply(channelId: channelId)
    }

    func createChannel(name: String, type: ChannelType, password: String?, ttl: MessageTTL) {
        let channel = Channel(
            id: "ch-\(UUID().uuidString.prefix(8))",
            name: name.uppercased(),
            type: type,
            members: [identity?.alias ?? ""],
            sharedKey: CryptoService.generateSymmetricKey(),
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

    private func simulateReply(channelId: String) {
        let aliases = nearbyNodes.isEmpty
            ? ["GHOST-X9", "WRAITH-B2", "SPECTER-7F"]
            : nearbyNodes.map(\.alias)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Double.random(in: 1.5...4.0)))
            let replies = [
                "copy that",
                "mesh relay confirmed",
                "signal strong here",
                "anyone else on this freq?",
                "acknowledged",
                "routing through node 3",
                "encrypted channel stable",
                "darknet protocol active",
            ]

            let reply = ChatMessage(
                id: UUID().uuidString,
                fromAlias: aliases.randomElement() ?? "UNKNOWN",
                fromKey: "",
                toTarget: "",
                channelId: channelId,
                content: replies.randomElement() ?? "...",
                hops: Int.random(in: 0...3),
                maxHops: settings.hopLimit,
                timestamp: Date(),
                ttl: nil,
                type: .msg,
                deliveryStatus: .delivered
            )

            var channelMessages = messages[channelId] ?? []
            channelMessages.append(reply)
            messages[channelId] = channelMessages

            if let idx = channels.firstIndex(where: { $0.id == channelId }) {
                channels[idx].lastActivity = Date()
                channels[idx].lastMessagePreview = reply.content
                channels[idx].unreadCount += 1
            }

            persistState()
        }
    }
}
