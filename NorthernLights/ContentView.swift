//
//  ContentView.swift
//  NorthernLights
//
//  Created by Craig Vella on 11/28/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var btc : BTConnection
    @EnvironmentObject var zones : Zones
    
    @State var saveComplete = false
    @State var showMoreOptions = false
    @State var showAddNewZone = false
    
    @State var selectedZone : ZoneLighting? = nil
    
    func saveCompleteAlert() -> Alert {
        Alert(
            title: Text("Configuration Saved"),
            message: Text("Northern Lights configuration saved to controller"),
            dismissButton: .default(Text("Okay")))
    }
    
    func addNewZoneAlert() -> Alert {
        Alert(title: Text("Create New Zone?"), primaryButton: .destructive(Text("Cancel")), secondaryButton: .default(Text("Create")) {
            zones.addNewBlankZone()
        })
    }
    
    var body: some View {
        ZStack {
            VStack {
                if (btc.isConnected) {
                    Spacer()
                        .frame(height: 20)
                    HStack(spacing: -20) {
                        Text("Northern Lights")
                            .font(Font.title)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Image(systemName: "square.and.arrow.down")
                            .frame(alignment: .trailing)
                            .alert(isPresented: self.$saveComplete, content: {
                                self.saveCompleteAlert()
                            })
                            .onTapGesture {
                                btc.BTSendSaveRequest()
                                self.saveComplete = true
                            }
                    }
                    Text("Lighting Control System")
                        .italic()
                    Spacer()
                        .frame(height: 20)
                    Image(systemName: "plus.app")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .alert(isPresented: self.$showAddNewZone, content: {
                            self.addNewZoneAlert()
                        })
                        .onTapGesture {
                            showAddNewZone = true
                        }
                    Spacer()
                        .frame(height: 20)
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                            ForEach($zones.zones) {
                                $zone in
                                ZStack{
                                    if zone.isOn {
                                        zone.color
                                    }
                                    VStack {
                                        Text(zone.zoneName)
                                            .font(.title2)
                                        Spacer()
                                        Image(systemName: zone.isOn ? "lightbulb" : "lightbulb.fill")
                                            .scaleEffect(x: 2,y: 2,anchor: .center)
                                        Spacer()
                                        Button("More Options") {
                                            selectedZone = zone
                                            showMoreOptions = true
                                        }
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: 150, minHeight: 150)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(.green, lineWidth: 1)
                                )
                                .onChange(of: zone) { newValue in
                                    btc.BTSendDataToWR(data: zones.serialize())
                                }
                                .onTapGesture {
                                    zone.isOn.toggle()
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
            .disabled(!btc.isConnected)
            .padding(.horizontal)
            .sheet(item: $selectedZone) { item in
                ZoneMoreOptions(zoneIndex: Int(item.zoneID))
            }
            
            
            ZStack {
                if !btc.isConnected {
                    Rectangle()
                        .foregroundColor(Color.gray)
                        .opacity(0.3)
                    VStack {
                        Text("Please wait, connecting...")
                            .frame(height: 100)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(x: 4, y: 4, anchor: .center)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let z : Zones = Zones(zoneArray: [ZoneLighting(ZoneID: 0, ZoneName: "Default")])
        let btc : BTConnection = BTConnection(ZoneObject: z, Debug: true)
        ContentView()
            .environmentObject(btc)
            .environmentObject(z)
    }
}
