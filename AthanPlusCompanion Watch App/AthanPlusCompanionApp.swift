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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(prayerTimeModel)
                // Schedule the first background refresh when the app launches
                // so midnight fetches work even if the user never reopens the app
                .onAppear {
                    scheduleNextBackgroundRefresh()
                }
        }
        .backgroundTask(.appRefresh) { _ in
            // Fired by the OS at midnight - fetch fresh data and reschedule
            await prayerTimeModel.fetch()
            scheduleNextBackgroundRefresh()
        }
        
    }
}

// Schedule the next background refresh
func scheduleNextBackgroundRefresh() {
    // Target midnight tonight so fresh data is fetched at the start of each new day
    let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now)
    
    WKApplication.shared().scheduleBackgroundRefresh(
        withPreferredDate: midnight,
        userInfo: nil
    ) {
        error in
        if let error = error {
            print("*** Error scheduling background refresh: \(error.localizedDescription) ***")
        } else {
            print("*** Background refresh scheduled for: \(midnight) ***")
        }
    }
}
