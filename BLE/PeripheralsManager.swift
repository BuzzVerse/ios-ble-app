//
//  PeripheralsManager.swift
//  BLE
//
//  Created by Krystian Wybranowski on 04/08/2024.
//

import Foundation

class PeripheralsManager: ObservableObject {
    static let shared = PeripheralsManager()
    
    @Published var connectedPeripheral: DiscoveredPeripheral?
    
    func disconnect() {
        connectedPeripheral = nil
    }
}
