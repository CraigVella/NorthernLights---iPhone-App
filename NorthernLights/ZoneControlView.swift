//
//  ContentView.swift
//  NorthernLights
//
//  Created by Craig Vella on 11/28/22.
//

import SwiftUI

struct ZoneControlView: View {
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
            if zones.addNewBlankZone() {
                btc.BTSendDataToWR()
            }
        })
    }
    
    var body: some View {
        VStack {
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
                        btc.BTSendDataToWR()
                        btc.BTSendSaveRequest()
                        self.saveComplete = true
                    }
            }
            Text("Lighting Control System")
                .italic()
            Text("Zones")
                .font(.title3)
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
                    ForEach($zones.zones.values) {
                        $zone in
                        ZStack{
                            VStack {
                                Text(zone.zoneName)
                                    .font(.title2)
                                Spacer()
                                Image(systemName: zone.isOn ? "power.circle.fill" : "power.circle")
                                    .scaleEffect(x: 2,y: 2,anchor: .center)
                                    .foregroundColor(zone.isOn ? .green : .red)
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
                                .stroke(zone.isOn ? zone.color : .black, lineWidth: 4)
                                .padding(4)
                        )
                        .onChange(of: zone) { newValue in
                            btc.BTSendDataToWR()
                        }
                        .onTapGesture {
                            zone.isOn.toggle()
                        }
                    }
                }
                Spacer()
            }
        }
        .disabled(!btc.isConnected)
        .padding(.horizontal)
        .sheet(item: $selectedZone) { item in
            ZoneMoreOptions(zoneIndex: Int(item.zoneID))
                .presentationDetents([.height(300)])
        }
        .background() {
            Image("Catalina36")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .opacity(0.5)
        }
    }
}

struct ZoneControlView_Previews: PreviewProvider {
    static var previews: some View {
        let z : Zones = Zones(zoneArray: [0:ZoneLighting(ZoneID: 0, ZoneName: "Default")])
        let btc : BTConnection = BTConnection(ZoneObject: z, Debug: true)
        ZoneControlView()
            .environmentObject(btc)
            .environmentObject(z)
    }
}
