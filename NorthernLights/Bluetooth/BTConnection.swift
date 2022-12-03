//
//  BTConnection.swift
//  NorthernLights
//
//  Created by Craig Vella on 11/28/22.
//

import Foundation
import Dispatch
import CoreBluetooth

class BTConnection : ObservableObject, BTManagerDelegate {
    
    @Published var isConnected:Bool     = false
    
    private var autoReconnect = true
    private var connectionAttempting = false
    private let BTQueue = DispatchQueue(label: "BTConnectionAttempting")
    private var btManager : BTManager!
    private var zoneObject : Zones!
    
    init(ZoneObject : Zones) {
        self.btManager = BTManager(delegate: self)
        self.zoneObject = ZoneObject
    }
    
    private func connectToNLBT() {
        BTQueue.async {
            while !self.btManager.canScanForConnection { sleep(1) } // Block and wait for powerup - you are on a different thread so its safe
            self.btManager.startScanning()
        }
    }
    
    func disconnect() {
        BTQueue.sync {
            sleep(1)
            btManager.disconnect()
        }
    }
    
    func setAutoReconnect(shouldReconnect :Bool) {
        BTQueue.sync { [unowned self] in
            autoReconnect = shouldReconnect
        }
    }
    
    func resestablishConnection() {
        guard autoReconnect else {
            return
        }
        if getConnectionAttempting() { return }
        if isConnected { return } // Check to see if you are already connected - then there is no need to reconnect
        setConnectionAttempting(isAttempting: true)  // Attempt a reconnect - or first connect
        self.connectToNLBT()
    }
    
    private func getConnectionAttempting() -> Bool {
        return BTQueue.sync() { [unowned self] in
            return self.connectionAttempting
        }
    }
    
    private func setConnectionAttempting(isAttempting:Bool) {
        BTQueue.sync { [unowned self] in
            self.connectionAttempting = isAttempting
        }
    }
    
    func BTDeviceConnected(deviceName: String) {
        print("BTDeviceConnected :: " + deviceName)
        DispatchQueue.main.async {
            self.isConnected = true
        }
        connectionAttempting = false
    }
    
    func BTDeviceDisconnected(deviceName: String) {
        print("BTDeviceDisconnected :: " + deviceName)
        DispatchQueue.main.async {
            self.isConnected = false
            self.resestablishConnection()
        }
    }
    
    func BTCanScanForConnection() {
        print("BTCanScanForConnection :: Recieved")
    }
    
    func BTReadData(data: Data) {
        print("BTReadData :: Recieved Data : Size: " + data.count.description)
        if !zoneObject.deserialize(buffer: data) {
            print("BTReadData :: Error Deserialzing Data")
        }
    }
    
    func BTSendDataToWR(data: Data) {
        guard isConnected else {
            print("BTSendDataToWR :: Trying to send Data while not connected");
            return
        }
        print("BTSendDataToWR :: Sending " +  data.count.description + " Bytes")
        btManager.sendDataUpdate(data: zoneObject.serialize())
    }
    
    func BTSendSaveRequest() {
        guard isConnected else {
            print("BTSendSaveRequest :: Trying to send save request while not connected");
            return
        }
        print("BTSendSaveRequest :: Sending Save Requst");
        btManager.sendSaveRequest()
    }
    
}
