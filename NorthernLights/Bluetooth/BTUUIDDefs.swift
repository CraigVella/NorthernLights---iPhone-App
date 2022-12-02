//
//  BTUUIDDefs.swift
//  NorthernLights
//
//  Created by Craig Vella on 11/30/22.
//

import Foundation
import CoreBluetooth

struct BTUUIDDefs {
    static let kBLEService_UUID = "382db2d8-07f4-4d24-957a-46e77b0cb345"
    static let kBLECharacteristic_WRData_UUID = "9a433dc3-30fa-48b6-bd04-627a17ec0704"
    static let kBLECharacteristic_ReqSave_UUID = "697fff61-1ffb-4acd-bd50-67b9ea085e17"
    
    static let BLEService_UUID = CBUUID(string: kBLEService_UUID)
    static let BLECharacteristic_WRData_UUID = CBUUID(string: kBLECharacteristic_WRData_UUID)
    static let BLECharacteristic_ReqSave_UUID = CBUUID(string: kBLECharacteristic_ReqSave_UUID)
}
