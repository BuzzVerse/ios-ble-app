//
//  LocationData.swift
//  BLE
//
//  Created by Krystian Wybranowski on 04/08/2024.
//

import Foundation

struct LocationData {
    var latitude: Double
    var longitude: Double
    
    func toData() -> Data {
        var data = Data()
        var latitude = self.latitude
        var longitude = self.longitude
        
        data.append(Data(bytes: &latitude, count: MemoryLayout.size(ofValue: latitude)))
        data.append(Data(bytes: &longitude, count: MemoryLayout.size(ofValue: longitude)))
        
        return data
    }
}
