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
    
    init() {
        self.zones = [
            ZoneLighting(ZoneID: 0, ZoneName: "Cabinets"),
            ZoneLighting(ZoneID: 1, ZoneName: "V-Berth")
        ]
    }
}

struct ZoneLighting : Identifiable {
    var zoneName   : String
    var zoneID     : Int
    var color : Color
    var isOn       : Bool
    var brightness : Double
    var id : Int { zoneID }
    
    init(ZoneID: Int, ZoneName: String) {
        self.zoneName = ZoneName
        self.zoneID = ZoneID
        self.color = Color.white
        self.isOn = false
        self.brightness = 0.5
    }
}
