//
//  ZoneMoreOptions.swift
//  NorthernLights
//
//  Created by Craig Vella on 12/4/22.
//

import Foundation
import SwiftUI

struct ZoneMoreOptions : View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var zones : Zones
    
    @State var showNameChange = false
    @State var previousName = ""
    
    var zoneIndex : Int
    
    var body : some View {
        VStack {
            Spacer()
                .frame(height: 30)
            HStack (spacing: -25) {
                Text(zones.zones[zoneIndex].zoneName)
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .center)
                Image(systemName: "pencil").onTapGesture {
                    previousName = zones.zones[zoneIndex].zoneName
                    showNameChange = true
                }
            }
            Text("Zone \(zones.zones[zoneIndex].zoneID + 1) - Additional Options")
            ColorPicker("Light Color", selection: $zones.zones[zoneIndex].color, supportsOpacity: false)
            HStack{
                Text("Brightness")
                Slider(value: $zones.zones[zoneIndex].brightness, in: 0...255, step: 1, label: {
                    Label("Brightness", systemImage: "lightbulb")
                })
            }
            Stepper(value: $zones.zones[zoneIndex].ledCount, in: 0...255) {
                Text("LED Count - " + Int(zones.zones[zoneIndex].ledCount).description)
            }
            Button("Close") {
                dismiss()
            }
            Spacer()
        }
        .padding(20)
        .alert("Change Name", isPresented: $showNameChange) {
            TextField("Name", text: $previousName).onChange(of: previousName) { _ in
                previousName = String(previousName.prefix(Int(Zones.ZONE_NAME_SIZE)-1))
            }
            Button(action:{}) {
                Text("Cancel").foregroundColor(.red)
            }
            Button("Save") {
                zones.zones[zoneIndex].zoneName = previousName
            }
        }
        .onAppear {
            
        }
    }
}

struct ZoneMoreOptions_Preview : PreviewProvider {
    static var previews: some View {
        let z = Zones(zoneArray: [ZoneLighting(ZoneID: 0, ZoneName: "TestZone")])
        ZoneMoreOptions(zoneIndex: 0)
            .environmentObject(z)
    }
}

