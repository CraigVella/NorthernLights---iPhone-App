//
//  ZoneLighting.swift
//  NorthernLights
//
//  Created by Craig Vella on 11/28/22.
//

import Foundation
import SwiftUI
import OrderedCollections

class Zones : ObservableObject {
    @Published var zones : OrderedDictionary<Int, ZoneLighting>
    @Published var zoneGroups : OrderedDictionary<Int, ZoneGroup>
    
    private var userDefaults = UserDefaults.standard
    
    static let ZONE_VERSION   : UInt8  = 2
    static let ZONE_NAME_SIZE : UInt8  = 11
    static let ZONE_MAX_ZONES : UInt8  = 8
    static let ZONE_GROUP_SAVE: String = "ZONEGROUPS"
    
    init() {
        self.zones = [:]
        self.zoneGroups = [:]
    }
    
    convenience init(zoneArray : OrderedDictionary<Int, ZoneLighting>, zoneGroups : OrderedDictionary<Int, ZoneGroup> = [:]) {
        self.init()
        self.zones = zoneArray
        self.zoneGroups = zoneGroups
    }
    
    func addNewBlankZone() -> Bool {
        let newId = getNextAvailableZoneID()
        guard newId.0 else {
            return false
        }
        zones[Int(newId.1)] = ZoneLighting(ZoneID: newId.1, ZoneName: "New Zone")
        return true
    }
    
    private func getNextAvailableZoneID() -> (Bool, UInt8) {
        for i in 0...Zones.ZONE_MAX_ZONES {
            if zones.index(forKey: Int(i)) == nil {
                return (true,i)
            }
        }
        return (false, 0)
    }
    
    func getNextAvailableZoneGroupID() -> Int {
        for i in 0...Int.max {
            if (zoneGroups.index(forKey: Int(i)) == nil) {
                return i
            }
        }
        return -1
    }
    
    func binding(for key: Int) -> Binding<ZoneLighting> {
        return Binding(get: {
            return self.zones[key] ?? ZoneLighting(ZoneID: 255, ZoneName: "Invalid")
        }, set: {
            self.zones[key] = $0
        })
    }
    
    func zoneGroupBinding(for key: Int) -> Binding<ZoneGroup> {
        return Binding(get: {
            return self.zoneGroups[key] ?? ZoneGroup(ZoneGroupName: "Invalid", ZoneSettings: ZoneLighting(ZoneID: 255, ZoneName: "Invalid"), ZoneIDs: [], z: self)
        }, set: {
            self.zoneGroups[key] = $0
        })
    }
    
    func saveZoneGroups() {
        do {
            let encoder = JSONEncoder();
            let data = try encoder.encode(zoneGroups)
            userDefaults.set(data, forKey: Zones.ZONE_GROUP_SAVE)
            print ("SaveZoneGroups :: Saved Zone Group Data")
        } catch {
            print (error)
        }
    }
    
    func restoreZoneGroups() {
        do {
            let decoder = JSONDecoder();
            let values = try decoder.decode(OrderedDictionary<Int, ZoneGroup>.self, from: userDefaults.data(forKey: Zones.ZONE_GROUP_SAVE) ?? Data())
            for zg in values.values {
                var zoneGroupValid = true
                for zid in zg.ZoneIDs {
                    if self.zones.index(forKey: Int(zid)) == nil {
                        zoneGroupValid = false
                    }
                }
                guard zoneGroupValid else {
                    continue
                }
                // We consider this a valid zone group - as all the zones it's grouping actually exist - restore them
                zg.setNewZonesObj(z: self)
                zg.ZoneGroupID = getNextAvailableZoneGroupID()
                zoneGroups[zg.ZoneGroupID] = zg
            }
        } catch {
            print(error)
        }
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
            returnData.append(contentsOf: [zone.value.zoneID])
            var zoneNameBuffer : [CChar] = Array(repeating: CChar(0), count: Int(Zones.ZONE_NAME_SIZE))
            if !zone.value.zoneName.getCString(&zoneNameBuffer, maxLength: Int(Zones.ZONE_NAME_SIZE), encoding: String.Encoding.utf8) {
                print("Zones :: WARN :: Error encoding zonename during serialization")
            }
            zoneNameBuffer.withUnsafeBytes { ptr in
                returnData.append(ptr.assumingMemoryBound(to: UInt8.self).baseAddress!, count: Int(Zones.ZONE_NAME_SIZE))
            }
            returnData.append(contentsOf: [
                UInt8(zone.value.brightness),
                zone.value.isOn ? 255 : 0,
                UInt8((zone.value.color.cgColor?.components![0])!*255),
                UInt8((zone.value.color.cgColor?.components![1])!*255),
                UInt8((zone.value.color.cgColor?.components![2])!*255),
                zone.value.ledCount
            ])
        }
        
        saveZoneGroups()
        
        return returnData
    }
    
    func deserialize(buffer:Data) -> Bool {
        var buffPtr = 0
        if buffer[buffPtr] != Zones.ZONE_VERSION {
            print("Zones :: Deserialization Failed Due to Zone Version Mismatch got " + String(buffer[buffPtr]) + " expected " + String(Zones.ZONE_VERSION))
            return false
        }
        
        self.zoneGroups.removeAll()
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
            zl.ledCount = buffer[buffPtr]
            buffPtr += 1
            
            self.zones[Int(zl.zoneID)] = zl
        }
        
        restoreZoneGroups()
        
        print("Zones :: Deserialization Complete");
        return true
    }
    
}

class ZoneGroup : Identifiable, Codable, ObservableObject {
    @Published var ZoneGroupName        : String
    @Published var ZoneSettings         : ZoneLighting
    @Published var ZoneIDs              : [UInt8]
    @Published var ZoneGroupID          : Int
    @Published var useZoneGroupLighting : Bool = false
    var id                   : Int {ZoneGroupID}
    private var zones : Zones
    
    enum onState {
        case on, off, middle
    }
    
    var isOn : onState {
        var hasOn  : Bool = false
        var hasOff : Bool = false
        for zid in ZoneIDs {
            if zones.zones[Int(zid)]?.isOn ?? false {
                hasOn = true
            } else if !(zones.zones[Int(zid)]?.isOn ?? true){
                hasOff = true
            }
        }
        var os : onState = .off
        if hasOn && hasOff { os = .middle }
        if !hasOn && hasOff { os = .off }
        if hasOn && !hasOff { os = .on }
        return os
    }
    
    init(ZoneGroupName: String, ZoneSettings: ZoneLighting, ZoneIDs: [UInt8], z : Zones) {
        self.ZoneGroupName = ZoneGroupName
        self.ZoneSettings = ZoneSettings
        self.ZoneIDs = ZoneIDs
        self.zones = z
        self.ZoneGroupID = z.getNextAvailableZoneGroupID()
    }
    
    enum CodingKeys: String, CodingKey {
        case ZoneGroupName
        case ZoneSettings
        case ZoneIDs
        case ZoneGroupID
        case useZoneGroupLighting
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.ZoneGroupName, forKey: .ZoneGroupName)
        try container.encode(self.ZoneSettings, forKey: .ZoneSettings)
        try container.encode(self.ZoneIDs, forKey: .ZoneIDs)
        try container.encode(self.useZoneGroupLighting, forKey: .useZoneGroupLighting)
    }
    
    func setNewZonesObj(z : Zones) {
        self.zones = z
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ZoneGroupName = try values.decode(String.self, forKey: .ZoneGroupName)
        ZoneSettings = try values.decode(ZoneLighting.self, forKey: .ZoneSettings)
        ZoneIDs = try values.decode([UInt8].self, forKey: .ZoneIDs)
        useZoneGroupLighting = try values.decode(Bool.self, forKey: .useZoneGroupLighting)
        ZoneGroupID = 255
        zones = Zones()
    }
}

struct ZoneLighting : Identifiable, Equatable, Codable {
    
    var zoneName    : String
    var zoneID      : UInt8
    var color       : Color
    var isOn        : Bool
    var brightness  : Double
    var ledCount    : UInt8
    var id          : UInt8 { zoneID }
    
    init(ZoneID: UInt8, ZoneName: String) {
        self.zoneName = ZoneName
        self.zoneID = ZoneID
        self.color = Color.white
        self.isOn = false
        self.brightness = 255
        self.ledCount = 0
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        zoneName = try values.decode(String.self, forKey: .zoneName)
        zoneID = try values.decode(UInt8.self, forKey: .zoneID)
        color = try Color(red:values.decode(Double.self, forKey: .colorR),
                          green: values.decode(Double.self, forKey: .colorG),
                          blue: values.decode(Double.self, forKey: .colorB))
        isOn = try values.decode(Bool.self, forKey: CodingKeys.isOn)
        brightness = try values.decode(Double.self, forKey: CodingKeys.brightness)
        ledCount = try values.decode(UInt8.self, forKey: CodingKeys.ledCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var e = encoder.container(keyedBy: CodingKeys.self)
        try e.encode(zoneName, forKey: .zoneName)
        try e.encode(zoneID, forKey: .zoneID)
        try e.encode(color.cgColor?.components?[0] ?? 0, forKey: .colorR)
        try e.encode(color.cgColor?.components?[1] ?? 0, forKey: .colorG)
        try e.encode(color.cgColor?.components?[2] ?? 0, forKey: .colorB)
        try e.encode(isOn, forKey: .isOn)
        try e.encode(brightness, forKey: .brightness)
        try e.encode(ledCount, forKey: .ledCount)
    }

    enum CodingKeys: String, CodingKey {
        case zoneName
        case zoneID
        case colorR
        case colorG
        case colorB
        case isOn
        case brightness
        case ledCount
    }
}
