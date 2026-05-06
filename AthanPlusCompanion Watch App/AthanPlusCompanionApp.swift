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
        .backgroundTask(.appRefresh) { context in
            print("Found matching task")
            await prayerTimeModel.fetch()
            await MainActor.run {
                scheduleNextBackgroundRefresh()
            }
            scheduleNextBackgroundRefresh()
//            await prayerTimeModel.fetch()
//            scheduleNextBackgroundRefresh()
        }
    }
}

// Schedule the next background refresh
func scheduleNextBackgroundRefresh() {
    let today = Calendar.current.startOfDay(for: .now)
    if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) {
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: tomorrow, userInfo: nil) { error in
            if let error = error {
                print("*** Error scheduling background refresh: \(error.localizedDescription) ***")
            } else {
                print("*** Scheduled! ***")
            }
        }
    }
}
