import Foundation
import SwiftUI

nonisolated struct NodeIdentity: Codable, Sendable, Identifiable {
    let id: String
    var alias: String
    var color: NodeColor
    var publicKey: String
    var privateKey: String
    let createdAt: Date

    static func generate(alias: String, color: NodeColor) -> NodeIdentity {
        let keyPair = CryptoService.generateKeyPair()
        return NodeIdentity(
            id: UUID().uuidString,
            alias: alias.uppercased(),
            color: color,
            publicKey: keyPair.publicKey,
            privateKey: keyPair.privateKey,
            createdAt: Date()
        )
    }
}

nonisolated enum NodeColor: String, Codable, Sendable, CaseIterable {
    case green, blue, red, orange, purple, white

    var swiftUIColor: Color {
        switch self {
        case .green: Color(hex: 0x00FF88)
        case .blue: Color(hex: 0x00AAFF)
        case .red: Color(hex: 0xFF0033)
        case .orange: Color(hex: 0xFF8800)
        case .purple: Color(hex: 0xAA00FF)
        case .white: .white
        }
    }
}
