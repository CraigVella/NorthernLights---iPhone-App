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
    
    var body: some View {
        ZStack {
            VStack {
                if (btc.isConnected) {
                    Spacer()
                        .frame(height: 20)
                    Text("Northern Lights")
                        .font(Font.title)
                    Text("Lighting Control System")
                        .italic()
                    Spacer()
                        .frame(height: 50)
                    ScrollView {
                        ForEach($zones.zones) {
                            $zone in
                            VStack{
                                HStack {
                                    Text("Zone \(zone.zoneID+1) - \(zone.zoneName)")
                                        .font(Font.title2)
                                    Image(systemName: "lightbulb")
                                }
                                Toggle("Lights On", isOn: $zone.isOn)
                                ColorPicker("Light Color", selection: $zone.color, supportsOpacity: false)
                                HStack{
                                    Text("Brightness")
                                    Slider(value: $zone.brightness, in: 0...1, label: {
                                        Label("Brightness", systemImage: "lightbulb")
                                    })
                                }
                            }
                            .padding(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(.green, lineWidth: 1)
                            )
                        }
                    }
                    Spacer()
                }
            }
            .disabled(!btc.isConnected)
            .padding(.horizontal)
            
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
        ContentView()
    }
}
