//
//  BLECommunicator.swift
//  BLE
//
//  Created by Krystian Wybranowski on 29/06/2024.
//

import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    @Published var discoveredPeripherals = [DiscoveredPeripheral]()
    @Published var isConnecting = false
    
    var centralManager: CBCentralManager!
    var updateTimer: Timer?
    let peripheralsManager = PeripheralsManager.shared
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan() {
        isConnecting = false
        if centralManager.state == .poweredOn {
            discoveredPeripherals.removeAll()
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "FACE")])
            //centralManager.scanForPeripherals(withServices: nil)
        }
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown, .resetting, .unsupported, .unauthorized, .poweredOff:
            stopScan()
        case .poweredOn:
            startScan()
        @unknown default:
            print("central.state is unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == peripheralsManager.connectedPeripheral?.peripheral {
            peripheralsManager.disconnect()
            stopUpdatingSensorData()
            print("Disconnected from \(peripheral.name ?? "Unknown Device")")
            startScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let advertisedData = advertisementData.map { "\($0): \($1)" }.sorted(by: { $0 < $1 }).joined(separator: "\n")
        let newPeripheral = DiscoveredPeripheral(peripheral: peripheral, advertisedData: advertisedData)
        
        
        if !discoveredPeripherals.contains(where: { $0.peripheral == peripheral }) {
            discoveredPeripherals.append(newPeripheral)
        }
    }
    
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        isConnecting = true
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnectFromPeripheral() {
        guard let peripheral = peripheralsManager.connectedPeripheral?.peripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        peripheral.readRSSI()
        peripheral.delegate = self
        peripheralsManager.connectedPeripheral = discoveredPeripherals.first(where: { $0.peripheral == peripheral })
        isConnecting = false
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        if let services = peripheral.services{
            for service in services{
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        for characteristic in service.characteristics! {
            if characteristic.uuid == CBUUID(string: "BEEF") {
                peripheralsManager.connectedPeripheral?.sensorCharacteristic = characteristic
                startUpdatingSensorData()
            }
            if characteristic.uuid == CBUUID(string: "CAFE") {
                peripheralsManager.connectedPeripheral?.locationCharacteristic = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed to write value: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.peripheralsManager.connectedPeripheral?.writeSuccess = false
            }
        } else {
            print("Successfully wrote value to characteristic \(characteristic.uuid)")
            DispatchQueue.main.async {
                self.peripheralsManager.connectedPeripheral?.writeSuccess = true
            }
        }
        peripheralsManager.connectedPeripheral?.isWritePending = false
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else { return }
        if characteristic == peripheralsManager.connectedPeripheral?.sensorCharacteristic,
           let data = characteristic.value {
            let sensorData = parseSensorData(data)
            DispatchQueue.main.async {
                self.peripheralsManager.connectedPeripheral?.sensorData = sensorData
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            print("Error reading RSSI: \(error!.localizedDescription)")
            return
        }
        DispatchQueue.main.async {
            self.peripheralsManager.connectedPeripheral?.rssi = Int(truncating: RSSI)
        }
        print("RSSI: \(RSSI)")
    }
    
    func startUpdatingSensorData() {
        readSensorData()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.readSensorData()
        }
    }
    
    func stopUpdatingSensorData() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func readSensorData() {
        guard let peripheral = peripheralsManager.connectedPeripheral?.peripheral,
              let characteristic = peripheralsManager.connectedPeripheral?.sensorCharacteristic else {
            return
        }
        peripheral.readValue(for: characteristic)
        peripheral.readRSSI()
    }
    
    func parseSensorData(_ data: Data) -> SensorData? {
        var sensorData = SensorData(temperature: 0, pressure: 0, humidity: 0)
        let dataSize = MemoryLayout<Double>.size
        
        guard data.count == 3 * dataSize else { return nil }
        
        sensorData.temperature = data.subdata(in: 0..<dataSize).withUnsafeBytes { $0.load(as: Double.self) }
        sensorData.pressure = data.subdata(in: dataSize..<(2 * dataSize)).withUnsafeBytes { $0.load(as: Double.self) }
        sensorData.humidity = data.subdata(in: (2 * dataSize)..<data.count).withUnsafeBytes { $0.load(as: Double.self) }
        
        return sensorData
    }
}
