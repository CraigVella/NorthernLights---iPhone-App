//
//  ZoneGroupView.swift
//  NorthernLights
//
//  Created by Craig Vella on 12/6/22.
//

import Foundation
import SwiftUI

struct ZoneGroupView : View {
    @EnvironmentObject var zones : Zones
    
    @State var showAddNewZoneGroup = false
    @State var showZoneGroupCreate = false
    @State var showMoreOptions = false
    @State var selectedZoneGroup : ZoneGroup? = nil
    
    func addNewZoneGroup() -> Alert {
        Alert(title: Text("Create New Zone Group?"), primaryButton: .destructive(Text("Cancel")), secondaryButton: .default(Text("Create")) {
            self.showZoneGroupCreate = true
        })
    }
    
    var body : some View {
        VStack {
            Text("Northern Lights")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Lighting Control System")
                .italic()
            Text("Zone Groups")
                .font(.title3)
            Spacer()
                .frame(height: 20)
            Image(systemName: "plus.app")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .alert(isPresented: self.$showAddNewZoneGroup, content: {
                    self.addNewZoneGroup()
                })
                .onTapGesture {
                    showAddNewZoneGroup = true
                }
            Spacer()
                .frame(height: 20)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()),GridItem(.flexible())]) {
                    ForEach($zones.zoneGroups.values) {
                        $zoneGroup in
                        ZStack{
                            VStack {
                                Text(zoneGroup.ZoneGroupName)
                                    .font(.title3)
                                    .truncationMode(.tail)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 130,height: 49, alignment: .top)
                                Spacer()
                                    .frame(height: 12)
                                Image(systemName: (zoneGroup.isOn == .on) ? "power.circle.fill" : "power.circle")
                                    .scaleEffect(x: 2,y: 2,anchor: .center)
                                    .foregroundColor(zoneGroup.isOn == .on ? .green : (zoneGroup.isOn == .middle ? .yellow : .black))
                                Spacer()
                                Button("More Options") {
                                    selectedZoneGroup = zoneGroup
                                    showMoreOptions = true
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: 150, minHeight: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke((zoneGroup.isOn != .off) ? zoneGroup.ZoneSettings.color : .black, lineWidth: 4)
                                .padding(4)
                        )
                        .onTapGesture {
                            var turnOn : Bool = false
                            if zoneGroup.isOn == .off { turnOn = true }
                            for zid in zoneGroup.ZoneIDs {
                                zones.zones[Int(zid)]?.isOn = turnOn
                                if zoneGroup.useZoneGroupLighting {
                                    zones.zones[Int(zid)]?.color = zoneGroup.ZoneSettings.color
                                    zones.zones[Int(zid)]?.brightness = zoneGroup.ZoneSettings.brightness
                                }
                            }
                        }
                        .sheet(item: $selectedZoneGroup) { zoneGroup in
                            ZoneGroupMoreOptions(zoneGroupID: zoneGroup.ZoneGroupID)
                                .presentationDetents([.height(300)])
                        }
                    }
                }
            }
            Spacer()
        }
        .background() {
            Image("Catalina36")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .opacity(0.5)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showZoneGroupCreate) {
            ZoneGroupCreate()
                .presentationDetents([.medium])
        }
    }
}

struct ZoneGroupView_Preview : PreviewProvider {
    static let z : Zones = Zones(zoneArray: [
        0 : ZoneLighting(ZoneID: 0, ZoneName: "Default 0"),
        1 : ZoneLighting(ZoneID: 1, ZoneName: "Default 1"),
        2 : ZoneLighting(ZoneID: 2, ZoneName: "Default 2"),
        3 : ZoneLighting(ZoneID: 3, ZoneName: "Default 3")
    ])
    static var previews: some View {
        ZoneGroupView()
            .environmentObject(z)
            .onAppear() {
                z.zoneGroups = [
                    0 : ZoneGroup(ZoneGroupName: "Zone Group Test", ZoneSettings: ZoneLighting(ZoneID: 255, ZoneName: "ZG-Holder"), ZoneIDs: [0,2], z: z)
                ]
            }
    }
}
