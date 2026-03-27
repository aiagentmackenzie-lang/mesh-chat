import Foundation
import CoreBluetooth

@Observable
class BLEMeshService: NSObject {
    var isBluetoothOn = false
    var isScanning = false
    var discoveredNodes: [MeshNode] = []
    var meshStatus: MeshStatus = .offline

    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?

    private let serviceUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
    private let characteristicUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")

    func initialize() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard let central = centralManager, central.state == .poweredOn else { return }
        isScanning = true
        meshStatus = .scanning
        central.scanForPeripherals(withServices: [serviceUUID], options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])

        generateSimulatedNodes()
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
        if !discoveredNodes.isEmpty {
            meshStatus = .active
        } else {
            meshStatus = .offline
        }
    }

    func sendMessage(_ packet: MeshPacket) {
        guard let data = try? JSONEncoder().encode(packet) else { return }
        peripheralManager?.updateValue(data, for: CBMutableCharacteristic(
            type: characteristicUUID,
            properties: .notify,
            value: nil,
            permissions: .readable
        ), onSubscribedCentrals: nil)
    }

    private func generateSimulatedNodes() {
        let aliases = ["GHOST-X9", "WRAITH-B2", "SPECTER-7F", "CIPHER-03", "SHADOW-A1", "PHANTOM-44"]
        let colors: [NodeColor] = [.green, .blue, .red, .purple, .orange, .white]

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard isScanning else { return }

            let count = Int.random(in: 2...5)
            var nodes: [MeshNode] = []
            for i in 0..<count {
                nodes.append(MeshNode(
                    id: UUID().uuidString,
                    alias: aliases[i % aliases.count],
                    color: colors[i % colors.count],
                    publicKey: CryptoService.generateKeyPair().publicKey,
                    rssi: Int.random(in: -90 ... -40),
                    isPaired: Bool.random(),
                    lastSeen: Date(),
                    status: [.paired, .unpaired, .unpaired][Int.random(in: 0...2)]
                ))
            }
            discoveredNodes = nodes
            meshStatus = .active
        }
    }
}

extension BLEMeshService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            isBluetoothOn = central.state == .poweredOn
            if central.state == .poweredOn {
                startScanning()
            } else {
                meshStatus = .offline
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            let deviceId = peripheral.identifier.uuidString
            if let index = discoveredNodes.firstIndex(where: { $0.id == deviceId }) {
                discoveredNodes[index].rssi = RSSI.intValue
                discoveredNodes[index].lastSeen = Date()
            } else {
                let node = MeshNode(
                    id: deviceId,
                    alias: "UNKNOWN-\(String(deviceId.prefix(4)).uppercased())",
                    color: .green,
                    rssi: RSSI.intValue,
                    isPaired: false,
                    lastSeen: Date(),
                    status: .unpaired
                )
                discoveredNodes.append(node)
            }
        }
    }
}

extension BLEMeshService: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            let characteristic = CBMutableCharacteristic(
                type: CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891"),
                properties: [.read, .write, .notify],
                value: nil,
                permissions: [.readable, .writeable]
            )
            let service = CBMutableService(type: CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"), primary: true)
            service.characteristics = [characteristic]
            peripheral.add(service)
        }
    }
}

nonisolated enum MeshStatus: String, Sendable {
    case scanning = "SCANNING"
    case active = "MESH ACTIVE"
    case offline = "OFFLINE"
}
