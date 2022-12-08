//
//  ZoneGroupCreate.swift
//  NorthernLights
//
//  Created by Craig Vella on 12/6/22.
//

import Foundation
import SwiftUI

struct ZoneGroupCreate : View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var zones : Zones
    
    @State var zoneGroupName : String = "New Zone Group"
    @State var newZoneGroupName = ""
    @State var showNameChange = false
    @State var selectedZones : [SelectableZone] = []
    
    var isSelected : Bool {
        var selectCount = 0
        for z in selectedZones {
            if z.selected {
                selectCount += 1
            }
        }
        if selectCount >= 1 {
            return true
        }
        return false
    }
    
    var body : some View {
        VStack {
            HStack(spacing: -20) {
                Text(zoneGroupName)
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .onTapGesture {
                        newZoneGroupName = zoneGroupName
                        showNameChange = true
                    }
                Image(systemName: "pencil")
                    .frame(alignment: .trailing)
                    .onTapGesture {
                        newZoneGroupName = zoneGroupName
                        showNameChange = true
                    }
            }
            Text("Select all zones you would like to add")
            Spacer()
                .frame(height: 20)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach($selectedZones) {
                        $selectable in
                        VStack {
                            Text(selectable.zoneName)
                                .font(.title2)
                                .padding(5)
                            Spacer()
                                .frame(height: 35)
                            Image(systemName: selectable.selected ? "checkmark.circle.fill" : "x.circle")
                                .scaleEffect(x: 4,y: 4, anchor: .center)
                        }
                        .padding(10)
                        .frame(maxWidth: 150, minHeight: 150, alignment: .top)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.green, lineWidth: 2)
                                .padding(4)
                        ).onTapGesture {
                            selectable.selected.toggle()
                        }
                    }
                }
            }
            Button("Save Group") {
                var zids : [UInt8] = []
                for selected in selectedZones {
                    if selected.selected {
                        zids.append(UInt8(selected.zoneID))
                    }
                }
                let newZG = ZoneGroup(ZoneGroupName: zoneGroupName, ZoneSettings: ZoneLighting(ZoneID: 255, ZoneName: "ZG-Holder"), ZoneIDs: zids, z: zones)
                zones.zoneGroups[newZG.ZoneGroupID] = newZG
                zones.saveZoneGroups()
                dismiss()
            }
            .disabled(!isSelected)
            Spacer()
            
        }
        .padding(.horizontal)
        .onAppear(){
            for z in zones.zones.values {
                selectedZones.append(SelectableZone(zoneName: z.zoneName, zoneID: Int(z.zoneID), selected: false))
            }
        }
        .alert("Set Zone Group Name",isPresented: $showNameChange) {
            TextField(newZoneGroupName, text: $newZoneGroupName)
            Button("Cancel") {}
            Button("Ok") {
                zoneGroupName = newZoneGroupName
            }
        }
    }
}

struct SelectableZone : Identifiable {
    var zoneName : String
    var zoneID   : Int
    var selected : Bool
    var id : Int {zoneID}
}

struct ZoneGroupCreate_Preview : PreviewProvider {
    static let z : Zones = Zones(zoneArray: [
        0 : ZoneLighting(ZoneID: 0, ZoneName: "Default 0"),
        1 : ZoneLighting(ZoneID: 1, ZoneName: "Default 1"),
        2 : ZoneLighting(ZoneID: 2, ZoneName: "Default 2"),
        3 : ZoneLighting(ZoneID: 3, ZoneName: "Default 3")
    ])
    static var previews: some View {
        ZoneGroupCreate()
            .environmentObject(z)
    }
}
