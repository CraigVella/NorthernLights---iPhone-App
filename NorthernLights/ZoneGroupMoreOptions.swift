//
//  ZoneGroupMoreOptions.swift
//  NorthernLights
//
//  Created by Craig Vella on 12/7/22.
//

import Foundation
import SwiftUI

struct ZoneGroupMoreOptions : View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var zones : Zones
    
    @State var showNameChange = false
    @State var showZoneDelete = false
    @State var previousName = ""
    @State var newSliderValue : Double = 0
    
    var zoneGroupID : Int
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 30)
            HStack (spacing: -25) {
                Image(systemName: "minus.circle")
                    .foregroundColor(.red)
                    .onTapGesture {
                        showZoneDelete = true
                    }
                    .alert("Delete Zone Group '\((zones.zoneGroups[zoneGroupID]?.ZoneGroupName ?? "Deleted") )'? ", isPresented: $showZoneDelete) {
                        Button(action:{}) {
                            Text("Cancel").foregroundColor(.red)
                        }
                        Button("Delete") {
                            zones.zoneGroups.removeValue(forKey: zoneGroupID)
                            zones.saveZoneGroups()
                            dismiss()
                        }
                    }
                Text(zones.zoneGroups[zoneGroupID]?.ZoneGroupName ?? "Deleted")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .center)
                Image(systemName: "pencil").onTapGesture {
                    previousName = zones.zoneGroups[zoneGroupID]?.ZoneGroupName ?? "Deleted"
                    showNameChange = true
                }
                .alert("Change Name", isPresented: $showNameChange) {
                    TextField("Name", text: $previousName)
                    Button("Cancel") {}
                    Button("Save") {
                        zones.zoneGroups[zoneGroupID]?.ZoneGroupName = previousName
                        zones.saveZoneGroups()
                    }
                }
            }
            Text("Additional Options")
            Toggle(isOn: zones.zoneGroupBinding(for: zoneGroupID).useZoneGroupLighting) {
                Text("Use Grouped Zone Options")
            }
            .onChange(of: zones.zoneGroups[zoneGroupID]?.useZoneGroupLighting) { newValue in
                if newValue ?? false {
                    for zid in zones.zoneGroups[zoneGroupID]?.ZoneIDs ?? [] {
                        zones.zones[Int(zid)]?.color = zones.zoneGroups[zoneGroupID]?.ZoneSettings.color ?? Color.white
                        zones.zones[Int(zid)]?.brightness = zones.zoneGroups[zoneGroupID]?.ZoneSettings.brightness ?? 255
                    }
                }
            }
            GroupBox("Grouped Zone Options") {
                ColorPicker("Light Color", selection: zones.zoneGroupBinding(for: zoneGroupID).ZoneSettings.color, supportsOpacity: false)
                HStack{
                    Text("Brightness - " + Int(((newSliderValue/255) * 100).rounded()).description + "%")
                    Slider(value: $newSliderValue, in: 0...255, step: 1, label: {
                        Label("Brightness", systemImage: "lightbulb")
                    }) {edit in
                        if !edit {
                            zones.zoneGroups[zoneGroupID]?.ZoneSettings.brightness = newSliderValue
                        }
                    }
                }
            }
            .onChange(of: zones.zoneGroups[zoneGroupID]?.ZoneSettings, perform: { _ in
                for zid in zones.zoneGroups[zoneGroupID]?.ZoneIDs ?? [] {
                    zones.zones[Int(zid)]?.color = zones.zoneGroups[zoneGroupID]?.ZoneSettings.color ?? Color.white
                    zones.zones[Int(zid)]?.brightness = zones.zoneGroups[zoneGroupID]?.ZoneSettings.brightness ?? 255
                }
            })
            .disabled(!(zones.zoneGroups[zoneGroupID]?.useZoneGroupLighting ?? true))
            Button("Close") {
                dismiss()
            }
            .font(.title2)
            Spacer()
        }
        .padding(20)
        .onAppear(){
            newSliderValue = zones.zoneGroups[zoneGroupID]?.ZoneSettings.brightness ?? 0
        }
    }
}

struct ZoneGroupMoreOptions_Preview : PreviewProvider {
    static let z = Zones(zoneArray: [
        0 : ZoneLighting(ZoneID: 0, ZoneName: "Test Zone"),
        1 : ZoneLighting(ZoneID: 1, ZoneName: "Zone Test 2")
    ])
    static var previews: some View {
        ZoneGroupMoreOptions(zoneGroupID: 0)
            .environmentObject(z)
            .onAppear() {
                z.zoneGroups = [0: ZoneGroup(ZoneGroupName: "Test Group", ZoneSettings: ZoneLighting(ZoneID: 255, ZoneName: "ZG-Holder"), ZoneIDs: [0], z: z)]
            }
    }
}
