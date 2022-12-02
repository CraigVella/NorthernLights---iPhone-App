//
//  BTManager.swift
//  NorthernLights
//
//  Created by Craig Vella on 11/29/22.
//

import Foundation
import CoreBluetooth

final class BTManager : NSObject {
    private var centralManager :  CBCentralManager!
    private var btmDelegate : BTManagerDelegate!
    private var connectedDevice : CBPeripheral!
    private var allZoneCharacteristic : CBCharacteristic!
    private var requestSaveZoneDataCharacteristic : CBCharacteristic!
    private var _canScanForConnection : Bool = false
    
    var canScanForConnection : Bool {
        get {
            return _canScanForConnection
        }
    }
    
    func startScanning() {
        if canScanForConnection {
            _canScanForConnection = false
            print("BTManager :: Scanning started...")
            centralManager.scanForPeripherals(withServices: [BTUUIDDefs.BLEService_UUID])
        }  else {
            print("BTManager :: Scan Requested but hardware not in correct state")
        }
    }
    
    override private init() {
        super.init()
    }
    
    init(delegate : BTManagerDelegate) {
        super.init()
        self.btmDelegate = delegate
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension BTManager : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print ("BTManager :: Discovered Services :: " + (error?.localizedDescription ?? "No Error"))
        guard let services = peripheral.services else {
            print ("BTManager :: Discovered Services :: Hmm... Services was empty?")
            return
        }
        services.forEach({ service in
            if service.uuid.uuidString.uppercased().isEqual(BTUUIDDefs.kBLEService_UUID.uppercased()) {
                print ("BTManager :: Found Service <" + BTUUIDDefs.kBLEService_UUID + "> :: Starting Characteristic Discovery")
                peripheral.discoverCharacteristics([BTUUIDDefs.BLECharacteristic_WRData_UUID, BTUUIDDefs.BLECharacteristic_ReqSave_UUID], for: service)
            }
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print ("BTManager :: Found Characteristics For Service <" + BTUUIDDefs.kBLEService_UUID + "> :: " + (error?.localizedDescription ?? "No Error"))
        guard let characteristics = service.characteristics else {
            print ("BTManager :: Hmm... Characteristics were empty?")
            return
        }
        characteristics.forEach({ characteristic in
            if characteristic.uuid.uuidString.uppercased().isEqual(BTUUIDDefs.kBLECharacteristic_WRData_UUID.uppercased()) {
                print ("BTManager :: Found Characteristic <" + BTUUIDDefs.kBLECharacteristic_WRData_UUID + "> :: DATA :: Registering For Changes")
                self.allZoneCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            } else if characteristic.uuid.uuidString.uppercased().isEqual(BTUUIDDefs.kBLECharacteristic_ReqSave_UUID.uppercased()) {
                print ("BTManager :: Found Characteristic <" + BTUUIDDefs.kBLECharacteristic_ReqSave_UUID + "> :: Request Save Characteristic")
                self.requestSaveZoneDataCharacteristic = characteristic
            }
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print ("BTManager :: New Value for Characteristic <" + characteristic.uuid.uuidString + "> :: Size = " + characteristic.value!.count.description)
        btmDelegate.BTReadData(data: characteristic.value!)
    }
    
}

extension BTManager : CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print ("BTManager :: Discovery :: " + (peripheral.name ?? "Unnamed Device"))
        print ("BTManager :: Attempting connection... ");
        peripheral.delegate = self
        self.connectedDevice = peripheral
        self.centralManager.connect(peripheral)
        self.centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print ("BTManager :: Connected :: " + (peripheral.name ?? "Unnamed Device"))
        print ("BTManager :: Looking for correct service")
        peripheral.discoverServices([BTUUIDDefs.BLEService_UUID]);
        btmDelegate.BTDeviceConnected(deviceName: (peripheral.name ?? "Unnamed Device"))
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print ("BTManager :: Failed to connect :: " +  (peripheral.name ?? "Unnamed Device") + " :: " + (error?.localizedDescription ?? "No Error"))
        _canScanForConnection = true
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print ("BTManager :: Peripheral Disconnected :: " + (peripheral.name ?? "Unnamed Device") + " :: " + (error?.localizedDescription ?? "No Error"))
        self.connectedDevice = nil
        self.allZoneCharacteristic = nil
        self.requestSaveZoneDataCharacteristic = nil;
        btmDelegate.BTDeviceDisconnected(deviceName: (peripheral.name ?? "Unnamed Device"))
        _canScanForConnection = true
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("BTManager :: Unknown")
        case .resetting:
            print("BTManager :: Resetting")
        case .unsupported:
            print("BTManager :: Unsupported")
        case .unauthorized:
            print("BTManager :: Unauthorized")
        case .poweredOff:
            print("BTManager :: Powered Off")
        case .poweredOn:
            print("BTManager :: Powered On")
            _canScanForConnection = true
            btmDelegate.BTCanScanForConnection()
        @unknown default:
            print("BTManager :: Really Unknown")
        }
    }
}

protocol BTManagerDelegate {
    func BTDeviceConnected(deviceName: String)
    func BTDeviceDisconnected(deviceName: String)
    func BTCanScanForConnection()
    func BTReadData(data: Data)
}
