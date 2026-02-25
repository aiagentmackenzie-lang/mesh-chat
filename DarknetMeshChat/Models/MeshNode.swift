import Foundation

nonisolated struct MeshNode: Codable, Sendable, Identifiable {
    let id: String
    var alias: String
    var color: NodeColor
    var publicKey: String?
    var rssi: Int
    var isPaired: Bool
    var lastSeen: Date
    var status: NodeStatus

    var distanceEstimate: String {
        if rssi > -60 { return "< 5m" }
        if rssi > -75 { return "5-15m" }
        if rssi > -85 { return "15-30m" }
        return "> 30m"
    }

    var distanceShort: String {
        if rssi > -60 { return "4m" }
        if rssi > -75 { return "12m" }
        if rssi > -85 { return "25m" }
        return "30m+" }

    var signalStrength: Int {
        let normalized = min(max((rssi + 100), 0), 50)
        return Int(Double(normalized) / 50.0 * 10.0)
    }
}

nonisolated enum NodeStatus: String, Codable, Sendable {
    case paired = "PAIRED"
    case unpaired = "UNPAIRED"
    case busy = "BUSY"
}
