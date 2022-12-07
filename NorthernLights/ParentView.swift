//
//  ParentView.swift
//  NorthernLights
//
//  Created by Craig Vella on 12/6/22.
//

import Foundation
import SwiftUI

struct ParentView : View {
    @EnvironmentObject var btc : BTConnection
    
    var body: some View {
        ZStack {
            if btc.isConnected {
                TabView {
                    ZoneControlView()
                        .tabItem {
                            Label("Zones", systemImage: "square.split.2x2")
                        }
                    ZoneGroupView()
                        .tabItem {
                            Label("Zone Groups", systemImage: "circle.grid.3x3.circle")
                        }
                }
            } else {
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
        .background() {
            Image("Catalina36")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .opacity(0.5)
        }
    }
}

struct ParentView_Previews: PreviewProvider {
    static var previews: some View {
        let z : Zones = Zones(zoneArray: [0:ZoneLighting(ZoneID: 0, ZoneName: "Default")])
        let btc : BTConnection = BTConnection(ZoneObject: z, Debug: true)
        ParentView()
            .environmentObject(btc)
            .environmentObject(z)
    }
}
