//
//  ZoneLighting.swift
//  NorthernLights
//
//  Created by Craig Vella on 11/28/22.
//

import Foundation
import SwiftUI

class Zones:ObservableObject {
    @Published var zones: [ZoneLighting]
    
    static let ZONE_VERSION   : UInt8 = 1
    static let ZONE_NAME_SIZE : UInt8 = 11
    
    init() {
        self.zones = []
    }
    
    func serialize() -> Data {
        var returnData : Data = Data.init()
        returnData.append(contentsOf: [
            Zones.ZONE_VERSION,
            UInt8(self.zones.count)
        ])
        
        guard self.zones.count != 0 else {
            print("Zones :: There were no zones to serialize")
            return returnData
        }
        
        for zone in self.zones {
            returnData.append(contentsOf: [zone.zoneID])
            var zoneNameBuffer : [CChar] = Array(repeating: CChar(0), count: Int(Zones.ZONE_NAME_SIZE))
            if !zone.zoneName.getCString(&zoneNameBuffer, maxLength: Int(Zones.ZONE_NAME_SIZE-1), encoding: String.Encoding.utf8) {
                print("Zones :: WARN :: Error encoding zonename during serialization")
            }
            zoneNameBuffer.withUnsafeBytes { ptr in
                returnData.append(ptr.assumingMemoryBound(to: UInt8.self).baseAddress!, count: Int(Zones.ZONE_NAME_SIZE))
            }
            returnData.append(contentsOf: [
                UInt8(zone.brightness),
                zone.isOn ? 255 : 0,
                UInt8((zone.color.cgColor?.components![0])!*255),
                UInt8((zone.color.cgColor?.components![1])!*255),
                UInt8((zone.color.cgColor?.components![2])!*255),
                zone.pin,
                zone.ledCount
            ])
        }
        
        return returnData
    }
    
    func deserialize(buffer:Data) -> Bool {
        var buffPtr = 0
        if buffer[buffPtr] != Zones.ZONE_VERSION {
            print("Zones :: Deserialization Failed Due to Zone Version Mismatch got " + String(buffer[buffPtr]) + " expected " + String(Zones.ZONE_VERSION))
            return false
        }
        self.zones.removeAll()
        buffPtr += 1
        let zoneCount = buffer[buffPtr]
        buffPtr += 1
        
        guard zoneCount != 0 else {
            print("Zones :: Deserialization ended due to Zone Count = 0")
            return false
        }
        
        for _ in 1...zoneCount {
            let zoneID = buffer[buffPtr]
            buffPtr += 1
            var cStringBuffer : [UInt8] = []
            buffer.subdata(in: buffPtr..<buffPtr+Int(Zones.ZONE_NAME_SIZE)).withUnsafeBytes { ptr in
                cStringBuffer.append(contentsOf: ptr)
            }
            let zoneName = String(cString: cStringBuffer)
            buffPtr += Int(Zones.ZONE_NAME_SIZE)
            var zl = ZoneLighting(ZoneID: zoneID, ZoneName: zoneName)
            zl.brightness = Double(buffer[buffPtr])
            buffPtr += 1
            zl.isOn = buffer[buffPtr] > 0 ? true : false
            buffPtr += 1
            let R = buffer[buffPtr]
            buffPtr += 1
            let G = buffer[buffPtr]
            buffPtr += 1
            let B = buffer[buffPtr]
            buffPtr += 1
            zl.color = Color(red: (Double(R)/255), green: (Double(G)/255), blue: (Double(B)/255))
            zl.pin = buffer[buffPtr]
            buffPtr += 1
            zl.ledCount = buffer[buffPtr]
            buffPtr += 1
            
            self.zones.append(zl)
        }
        
        print("Zones :: Deserialization Complete");
        return true
    }
    
}

struct ZoneLighting : Identifiable {
    var zoneName    : String
    var zoneID      : UInt8
    var color       : Color
    var isOn        : Bool
    var brightness  : Double
    var pin         : UInt8
    var ledCount    : UInt8
    var id          : UInt8 { zoneID }
    
    init(ZoneID: UInt8, ZoneName: String) {
        self.zoneName = ZoneName
        self.zoneID = ZoneID
        self.color = Color.white
        self.isOn = false
        self.brightness = 255
        self.pin = 0
        self.ledCount = 0
    }
}
