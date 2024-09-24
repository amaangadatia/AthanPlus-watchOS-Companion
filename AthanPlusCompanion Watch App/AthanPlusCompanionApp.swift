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
        }
        .backgroundTask(.appRefresh("TIMINGS_REFRESH")) {
            print("Found matching task")
            await prayerTimeModel.fetch()
            scheduleNextBackgroundRefresh()
        }
    }
}

// Schedule the next background refresh
func scheduleNextBackgroundRefresh() {
    let today = Calendar.current.startOfDay(for: .now)
    if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) {
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: tomorrow, userInfo: "TIMINGS_REFRESH" as NSSecureCoding & NSObjectProtocol) { error in
            if error != nil {
                fatalError("*** An error occurred while scheduling the background refresh task. ***")
            }
            print("*** Scheduled! ***")
        }
    }
}
