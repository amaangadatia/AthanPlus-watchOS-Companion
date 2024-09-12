//
//  ComplicationProvider.swift
//  ComplicationProvider
//
//  Created by Amaan Gadatia on 9/11/24.
//

import WidgetKit
import SwiftUI

struct PrayerComplicationEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerTime: String
}

struct PrayerComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerComplicationEntry {
        PrayerComplicationEntry(date: Date(), nextPrayerName: "Fajr", nextPrayerTime: "5:00AM")
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerComplicationEntry) -> ()) {
        let entry = PrayerComplicationEntry(date: Date(), nextPrayerName: "Fajr", nextPrayerTime: "5:00AM")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerComplicationEntry>) -> ()) {
        if let prayerTimes = loadPrayerTimesFromSharedDefaults() {
            let nextPrayer = getNextPrayerTime(from: prayerTimes)
            let currentDate = Date()
            
            let entry = PrayerComplicationEntry(date: currentDate, nextPrayerName: nextPrayer.name, nextPrayerTime: nextPrayer.time)
            let timeline = Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(60 * 60)))
            completion(timeline)
        } else {
            let currentDate = Date()
            let entry = PrayerComplicationEntry(date: currentDate, nextPrayerName: "Fajr", nextPrayerTime: "5:00 AM")
            let timeline = Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(60 * 60)))
            completion(timeline)
        }
    }
    
    // Helper function to load prayer times from shared UserDefaults
    private func loadPrayerTimesFromSharedDefaults() -> PrayerTimesResponse? {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.AthanPlusCompanion"),
           let data = sharedDefaults.data(forKey: "prayerTimes") {
            do {
                let prayerTimes = try JSONDecoder().decode(PrayerTimesResponse.self, from: data)
                return prayerTimes
            } catch {
                print("Failed to decode prayer times: \(error)")
                return nil
            }
        }
        return nil
    }
    
    // Function to get the next prayer time
    func getNextPrayerTime(from prayerTimes: PrayerTimesResponse) -> (name: String, time: String) {
        let currentDate = Date()

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        // Formats current time as 'HH:MM AM/PM'
        let currentTime = formatter.string(from: currentDate)
        
        var nextPrayerName = ""
        var nextPrayerTime = ""
        
        if let currTime = formatter.date(from: currentTime), let fajrIqamah = formatter.date(from: prayerTimes.data.iqamah.first?.fajr ?? ""), let zuhrIqamah = formatter.date(from: prayerTimes.data.iqamah.first?.zuhr ?? ""), let asrIqamah = formatter.date(from: prayerTimes.data.iqamah.first?.asr ?? ""), let maghribIqamah = formatter.date(from: prayerTimes.data.iqamah.first?.maghrib ?? ""), let ishaIqamah = formatter.date(from: prayerTimes.data.iqamah.first?.isha ?? "") {
            
            // If current time is after Isha or before Fajr, then Fajr is the next prayer
            if currTime >= ishaIqamah || currTime < fajrIqamah {
                nextPrayerName = "Fajr"
                nextPrayerTime = prayerTimes.data.iqamah.first?.fajr ?? ""
            }
            else {
                if currTime >= maghribIqamah && currTime < ishaIqamah {     // If current time is between Maghrib and Isha, then Isha is the next prayer
                    nextPrayerName = "Isha"
                    nextPrayerTime = prayerTimes.data.iqamah.first?.isha ?? ""
                }
                
                else if currTime >= asrIqamah && currTime < maghribIqamah { // If current time is between Asr and Maghrib, then Maghrib is the next prayer
                    nextPrayerName = "Maghrib"
                    nextPrayerTime = prayerTimes.data.iqamah.first?.maghrib ?? ""
                }
                
                else if currTime >= zuhrIqamah && currTime < asrIqamah {    // If current time is between Zuhr and Asr, then Asr is the next prayer
                    nextPrayerName = "Asr"
                    nextPrayerTime = prayerTimes.data.iqamah.first?.asr ?? ""
                }
                
                else if currTime >= fajrIqamah && currTime < zuhrIqamah {   // If current time is between Fajr and Zuhr, then Zuhr is the next prayer
                    nextPrayerName = "Zuhr"
                    nextPrayerTime = prayerTimes.data.iqamah.first?.zuhr ?? ""
                }
            }
        }
        
        return (name: nextPrayerName, time: nextPrayerTime)
    }
}

struct PrayerComplicationView : View {
    var entry: PrayerComplicationEntry
    
//    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Circle()
                .fill(.black.gradient)
            VStack {
                Text(entry.nextPrayerName)
                    .font(.system(size: 15))
                    .bold()
                Text(entry.nextPrayerTime)
                    .font(.system(size: 10))
            }
        }
    }
}

@main
struct ComplicationProvider: Widget {
    let kind: String = "ComplicationProvider"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerComplicationProvider()) { entry in
            if #available(watchOS 10.0, *) {
                PrayerComplicationView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                PrayerComplicationView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Athan+ Widget")
        .description("Shows the next prayer time.")
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    ComplicationProvider()
} timeline: {
    PrayerComplicationEntry(date: .now, nextPrayerName: "Maghrib", nextPrayerTime: "7:18PM")
    PrayerComplicationEntry(date: .now, nextPrayerName: "Fajr", nextPrayerTime: "5:00AM")
}
