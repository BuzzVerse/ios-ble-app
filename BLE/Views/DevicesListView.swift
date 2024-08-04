//
//  DevicesListView.swift
//  BLE
//
//  Created by Krystian Wybranowski on 04/08/2024.
//

import SwiftUI

struct DevicesListView: View {
    @ObservedObject private var peripheralsManager = PeripheralsManager.shared
    @ObservedObject private var bluetoothScanner = BluetoothScanner()
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            List(bluetoothScanner.discoveredPeripherals, id: \.peripheral.identifier) { peripheral in
                Button(action: {
                    bluetoothScanner.connectToPeripheral(peripheral.peripheral)
                }) {
                    HStack {
                        Text(peripheral.peripheral.name ?? "Unknown Device")
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }.contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .overlay(
                bluetoothScanner.isConnecting ?
                VStack {
                    ProgressView()
                        .scaleEffect(2)
                        .padding()
                    Button("Cancel") {
                        bluetoothScanner.startScan()
                    }
                } : nil
            )
            .navigationTitle("🛜 BLE Devices")
            .navigationDestination(for: DiscoveredPeripheral.self) { peripheral in
                ConnectedDeviceView()
            }
            .onAppear {
                bluetoothScanner.disconnectFromPeripheral()
                bluetoothScanner.startScan()
            }
            .onDisappear {
                bluetoothScanner.stopScan()
            }
        }
        .onChange(of: peripheralsManager.connectedPeripheral?.id) {
            guard let peripheral = peripheralsManager.connectedPeripheral else {
                navPath.removeLast()
                return
            }
            navPath.append(peripheral)
        }
    }
}

#Preview {
    DevicesListView()
}
