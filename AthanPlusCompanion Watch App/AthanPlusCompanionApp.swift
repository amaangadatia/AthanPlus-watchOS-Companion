//
//  AthanPlusCompanionApp.swift
//  AthanPlusCompanion Watch App
//
//  Created by Amaan Gadatia on 9/9/24.
//

import SwiftUI
import WatchKit

@main
struct AthanPlusCompanion_Watch_AppApp: App {
    @StateObject var prayerTimeModel = PrayerTimesModel()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(prayerTimeModel)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                prayerTimeModel.fetch()
            }
        }
    }
}
