//
//  NorthernLightsApp.swift
//  NorthernLights
//
//  Created by Craig Vella on 11/28/22.
//

import SwiftUI

@main
struct NorthernLightsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var zones = Zones()
    var btc : BTConnection!
    
    init() {
        btc = BTConnection(ZoneObject: zones)
    }
    
    var body: some Scene {
        WindowGroup {
            ParentView()
                .environmentObject(btc)
                .environmentObject(zones)
        }.onChange(of: scenePhase) { phase in
            if phase == .active {
                btc.setAutoReconnect(shouldReconnect: true)
                btc.resestablishConnection()
            } else if phase == .background {
                btc.setAutoReconnect(shouldReconnect: false)
                btc.disconnect()
            }
        }
    }
}
