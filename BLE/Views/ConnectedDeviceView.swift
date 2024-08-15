//
//  ConnectedDeviceView.swift
//  BLE
//
//  Created by Krystian Wybranowski on 04/08/2024.
//

import SwiftUI
import CoreBluetooth

struct ConnectedDeviceView: View {
    @ObservedObject private var peripheralsManager = PeripheralsManager.shared
    @ObservedObject private var locationManager = LocationManager()
    
    var body: some View {
        let peripheral = peripheralsManager.connectedPeripheral
        
        List {
            Section {
                if let rssi = peripheral?.rssi {
                    let rssiPercentage = rssiToPercentage(rssi: rssi)
                    let symbolValue = Double(rssiPercentage) / 100.0
                    
                    HStack {
                        Text("RSSI: \(rssi) dBm")
                        Spacer()
                        Image(systemName: "cellularbars", variableValue: symbolValue)
                            .renderingMode(.original)
                            .foregroundColor(Color(.systemPink))
                    }.badge("\(rssiPercentage)%")
                }
                
                Text(peripheral?.advertisedData ?? "No data")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Section {
                if let sensorData = peripheral?.sensorData {
                    Text("Temperature: \(String(format: "%.2f", sensorData.temperature)) ℃")
                    Text("Pressure: \(String(format: "%.0f", sensorData.pressure)) hPa")
                    Text("Humidity: \(String(format: "%.2f", sensorData.humidity)) %")
                } else {
                    Text("No sensor data available")
                }
            }
            
            if let location = locationManager.location {
                Text("Latitude: \(location.coordinate.latitude)")
                Text("Longitude: \(location.coordinate.longitude)")
                
                let latitude = location.coordinate.latitude * 100000
                let longitude = location.coordinate.longitude * 100000
                
                Button(action: {
                    sendLocationData(
                        latitude: Int32(latitude),
                        longitude: Int32(longitude)
                    )
                }) {
                    HStack {
                        Text("Send Location Data")
                        Spacer()
                        if let isWritePending = peripheralsManager.connectedPeripheral?.isWritePending {
                            isWritePending ? ProgressView() : nil
                        }
                        if let writeSuccess = peripheral?.writeSuccess {
                            Text(writeSuccess ? "✅" : "🛑")
                        }
                    }
                }
            }
        }
        .navigationTitle(peripheral?.peripheral.name ?? "Unknown Device")
        .onAppear {
            locationManager.requestLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .onChange(of: locationManager.location) {
            guard let location = locationManager.location,
                  let peripheral = peripheralsManager.connectedPeripheral,
                  !peripheral.isWritePending,
                  peripheral.locationCharacteristic != nil else { return }
            
            let latitude = location.coordinate.latitude * 100000
            let longitude = location.coordinate.longitude * 100000
                
            sendLocationData(
                latitude: Int32(latitude),
                longitude: Int32(longitude)
            )
        }
    }
    
    func sendLocationData(latitude: Int32, longitude: Int32) {
        peripheralsManager.connectedPeripheral?.writeSuccess = nil
        guard let peripheral = peripheralsManager.connectedPeripheral?.peripheral,
              let characteristic = peripheralsManager.connectedPeripheral?.locationCharacteristic else {
            peripheralsManager.connectedPeripheral?.writeSuccess = false
            return
        }
        
        peripheralsManager.connectedPeripheral?.isWritePending = true

        let locationData = LocationData(status: 1, altitude: 1, latitude: latitude, longitude: longitude)
        let dataToSend = locationData.toData()
        
        peripheral.writeValue(dataToSend, for: characteristic, type: .withResponse)
    }
    
    func rssiToPercentage(rssi: Int) -> Int {
        let minRSSI = -100
        let maxRSSI = -40
        
        if rssi < minRSSI {
            return 0
        } else if rssi > maxRSSI {
            return 100
        } else {
            return Int(((Double(rssi) - Double(minRSSI)) / Double(maxRSSI - minRSSI)) * 100)
        }
    }
}
