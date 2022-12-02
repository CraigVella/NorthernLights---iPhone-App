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
    
    var btc = BTConnection()
    var zones = Zones()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(btc)
                .environmentObject(zones)
        }.onChange(of: scenePhase) { phase in
            if phase == .active {
                btc.resestablishConnection()
            } else if phase == .background {
                btc.disconnect()
            }
        }
    }
}
