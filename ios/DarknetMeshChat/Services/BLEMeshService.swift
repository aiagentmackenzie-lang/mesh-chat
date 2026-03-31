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
    
    // Track connected peripherals and discovered characteristics
    private var connectedPeripherals: [CBPeripheral] = []
    private var peripheralCharacteristics: [CBPeripheral: CBCharacteristic] = [:]
    private var connectingPeripheralIDs: Set<UUID> = []
    
    // Store local mutable characteristic for peripheral mode
    private var localCharacteristic: CBMutableCharacteristic?
    private var localService: CBMutableService?

    private let serviceUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
    private let characteristicUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")
    
    // Callbacks are provided by the view model so BLE can stay transport-focused.
    var channelKeyProvider: ((String) -> String?)?
    var onMessageReceived: ((MeshPacket, String) -> Void)?

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
    
    func disconnectAll() {
        for peripheral in connectedPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals.removeAll()
        peripheralCharacteristics.removeAll()
        connectingPeripheralIDs.removeAll()
    }

    func sendMessage(_ packet: MeshPacket) {
        guard let data = try? JSONEncoder().encode(packet) else { return }
        
        // Write to all connected peripherals
        for (peripheral, characteristic) in peripheralCharacteristics {
            guard peripheral.state == .connected else { continue }
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
        
        // Also update local characteristic for centrals that are subscribed to us
        if let localChar = localCharacteristic {
            peripheralManager?.updateValue(data, for: localChar, onSubscribedCentrals: nil)
        }
    }
    
    func sendMessageToSpecificPeer(_ packet: MeshPacket, peerId: String) {
        guard let data = try? JSONEncoder().encode(packet) else { return }
        
        // Find the peripheral with matching identifier
        for (peripheral, characteristic) in peripheralCharacteristics {
            if peripheral.identifier.uuidString == peerId,
               peripheral.state == .connected {
                peripheral.writeValue(data, for: characteristic, type: .withResponse)
                return
            }
        }
    }

    private func processIncomingPacketData(_ data: Data, source: String) {
        guard let packet = try? JSONDecoder().decode(MeshPacket.self, from: data) else {
            print("[BLE] Failed to decode packet from \(source)")
            return
        }

        guard let key = channelKeyProvider?(packet.channel) else {
            print("[BLE] Missing channel key for \(packet.channel)")
            return
        }

        guard let decryptedPayload = CryptoService.decrypt(packet.payload, key: key) else {
            print("[BLE] Failed to decrypt packet \(packet.id) on \(packet.channel)")
            return
        }

        print("[BLE] Received message \(packet.id) from \(packet.from) via \(source)")

        Task { @MainActor in
            onMessageReceived?(packet, decryptedPayload)
        }
    }
}

// MARK: - CBCentralManagerDelegate
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
            let advertisedName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)?.uppercased()
            
            // Update or add discovered node
            if let index = discoveredNodes.firstIndex(where: { $0.id == deviceId }) {
                discoveredNodes[index].rssi = RSSI.intValue
                discoveredNodes[index].lastSeen = Date()
                if let advertisedName {
                    discoveredNodes[index].alias = advertisedName
                }
            } else {
                let node = MeshNode(
                    id: deviceId,
                    alias: advertisedName ?? "UNKNOWN-\(String(deviceId.prefix(4)).uppercased())",
                    color: .green,
                    rssi: RSSI.intValue,
                    isPaired: false,
                    lastSeen: Date(),
                    status: .unpaired
                )
                discoveredNodes.append(node)
            }
            
            // Connect to the peripheral if not already connected or connecting
            if peripheral.state != .connected &&
                peripheral.state != .connecting &&
                !connectingPeripheralIDs.contains(peripheral.identifier) {
                connectingPeripheralIDs.insert(peripheral.identifier)
                peripheral.delegate = self
                central.connect(peripheral, options: nil)
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            print("[BLE] Connected to peripheral: \(peripheral.identifier.uuidString)")
            connectingPeripheralIDs.remove(peripheral.identifier)
            
            // Track connected peripheral
            if !connectedPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                connectedPeripherals.append(peripheral)
            }
            
            // Discover services
            peripheral.discoverServices([serviceUUID])
            
            // Update node status
            if let index = discoveredNodes.firstIndex(where: { $0.id == peripheral.identifier.uuidString }) {
                discoveredNodes[index].status = .paired
                discoveredNodes[index].isPaired = true
            }

            meshStatus = .active
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[BLE] Failed to connect to peripheral: \(peripheral.identifier.uuidString), error: \(String(describing: error))")
        Task { @MainActor in
            connectingPeripheralIDs.remove(peripheral.identifier)
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            print("[BLE] Disconnected from peripheral: \(peripheral.identifier.uuidString)")
            
            // Remove from connected peripherals
            connectedPeripherals.removeAll { $0.identifier == peripheral.identifier }
            peripheralCharacteristics.removeValue(forKey: peripheral)
            connectingPeripheralIDs.remove(peripheral.identifier)
            
            // Update node status
            if let index = discoveredNodes.firstIndex(where: { $0.id == peripheral.identifier.uuidString }) {
                discoveredNodes[index].status = .unpaired
                discoveredNodes[index].isPaired = false
            }

            meshStatus = connectedPeripherals.isEmpty ? (isScanning ? .scanning : .offline) : .active
            
            // Attempt to reconnect
            if isScanning {
                connectingPeripheralIDs.insert(peripheral.identifier)
                central.connect(peripheral, options: nil)
            }
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLEMeshService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("[BLE] Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == serviceUUID {
                print("[BLE] Found service, discovering characteristics...")
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("[BLE] Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        Task { @MainActor in
            for characteristic in characteristics {
                if characteristic.uuid == characteristicUUID {
                    print("[BLE] Found characteristic, subscribing to notifications...")
                    peripheralCharacteristics[peripheral] = characteristic
                    
                    // Subscribe to notifications for this characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[BLE] Error updating value: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else { return }

        processIncomingPacketData(data, source: peripheral.identifier.uuidString)
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[BLE] Error updating notification state: \(error.localizedDescription)")
            return
        }
        
        print("[BLE] Notification state updated for characteristic: \(characteristic.isNotifying)")
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[BLE] Error writing value: \(error.localizedDescription)")
        } else {
            print("[BLE] Successfully wrote value to characteristic")
        }
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BLEMeshService: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            print("[BLE] Peripheral manager powered on, setting up service...")
            
            // Create mutable characteristic
            let characteristic = CBMutableCharacteristic(
                type: characteristicUUID,
                properties: [.read, .write, .notify],
                value: nil,
                permissions: [.readable, .writeable]
            )
            
            Task { @MainActor in
                localCharacteristic = characteristic
                
                // Create service
                let service = CBMutableService(type: serviceUUID, primary: true)
                service.characteristics = [characteristic]
                localService = service
                
                // Add service to peripheral manager
                peripheral.add(service)
            }
        }
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("[BLE] Error adding service: \(error.localizedDescription)")
        } else {
            print("[BLE] Service added successfully, starting advertising...")
            // Start advertising
            peripheral.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
                CBAdvertisementDataLocalNameKey: "DarknetMesh"
            ])
        }
    }
    
    nonisolated func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("[BLE] Error starting advertising: \(error.localizedDescription)")
        } else {
            print("[BLE] Started advertising successfully")
        }
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("[BLE] Central subscribed to characteristic: \(central.identifier.uuidString)")
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("[BLE] Central unsubscribed from characteristic: \(central.identifier.uuidString)")
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard let data = request.value else { continue }

            processIncomingPacketData(data, source: request.central.identifier.uuidString)
        }
        
        // Respond with success
        peripheral.respond(to: requests[0], withResult: .success)
    }
}

nonisolated enum MeshStatus: String, Sendable {
    case scanning = "SCANNING"
    case active = "MESH ACTIVE"
    case offline = "OFFLINE"
}
