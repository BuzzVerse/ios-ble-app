//
//  LocationData.swift
//  BLE
//
//  Created by Krystian Wybranowski on 04/08/2024.
//

import Foundation

struct LocationData {
    var status: UInt8
    var altitude: UInt16
    var latitude: Int32
    var longitude: Int32
    
    func toData() -> Data {
        var data = Data()
        var status = self.status
        var altitude = self.altitude
        var latitude = self.latitude
        var longitude = self.longitude
        
        data.append(Data(bytes: &status, count: MemoryLayout.size(ofValue: status)))
        data.append(Data(bytes: &altitude, count: MemoryLayout.size(ofValue: altitude)))
        data.append(Data(bytes: &latitude, count: MemoryLayout.size(ofValue: latitude)))
        data.append(Data(bytes: &longitude, count: MemoryLayout.size(ofValue: longitude)))
        
        return data
    }
}
