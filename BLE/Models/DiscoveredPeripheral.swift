//
//  DiscoveredPeripheral.swift
//  BLE
//
//  Created by Krystian Wybranowski on 04/08/2024.
//

import Foundation
import CoreBluetooth

struct DiscoveredPeripheral: Hashable, Identifiable {
    let id = UUID()
    var rssi: Int?
    var peripheral: CBPeripheral
    var sensorCharacteristic: CBCharacteristic?
    var locationCharacteristic: CBCharacteristic?
    var advertisedData: String
    var sensorData: SensorData?
    var isWritePending = false
    var writeSuccess: Bool?
}
