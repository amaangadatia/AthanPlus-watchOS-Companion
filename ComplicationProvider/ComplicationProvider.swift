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
        print("DEBUG getTimeline called")
        
        guard let prayerTimes = loadPrayerTimesFromSharedDefaults() else {
            print("DEBUG loadPrayerTimes returned nil — showing placeholder")
            let entry = PrayerComplicationEntry(date: Date(), nextPrayerName: "Fajr", nextPrayerTime: "5:00 AM")
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
            completion(timeline)
            return
        }
        
        print("DEBUG loadPrayerTimes succeeded")
        
        let entries = buildTimelineEntries(from: prayerTimes)
        
        
        // If we only got one entry it means today's data wasn't matched (stale cache after midnight)
        // Retry in 15 mins to give the background refresh to complete and write fresh data
        if entries.count == 1 {
            let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(15 * 60)))
            completion(timeline)
        }
        else {
            // .atEnd tells WidgetKit to call getTimeline again after the last entry
            // so it can fetch fresh data for the next day
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
    
    private func buildTimelineEntries(from prayerTimes: PrayerTimesResponse) -> [PrayerComplicationEntry] {
        let currentDate = Date()
        let calendar = Calendar.current
        let dateFmt = makeDateFormatter()
        let timeFmt = makeTimeFormatter()
        let todayString = dateFmt.string(from: currentDate)

        guard let todayIqamah = prayerTimes.data.iqamah.first(where: { $0.date == todayString }) else {
            let fallbackTime = prayerTimes.data.iqamah.first?.fajr ?? "-"
            return [PrayerComplicationEntry(date: currentDate, nextPrayerName: "Fajr", nextPrayerTime: fallbackTime)]
        }

        let prayers: [(name: String, timeStr: String)] = [
            ("Fajr",    todayIqamah.fajr),
            ("Zuhr",    todayIqamah.zuhr),
            ("Asr",     todayIqamah.asr),
            ("Maghrib", todayIqamah.maghrib),
            ("Isha",    todayIqamah.isha)
        ]

        var entries: [PrayerComplicationEntry] = []

        // Insert immediate entry for right now
        let currentNextPrayer = getNextPrayerTime(from: prayerTimes)
        entries.append(PrayerComplicationEntry(
            date: currentDate,
            nextPrayerName: currentNextPrayer.name,
            nextPrayerTime: currentNextPrayer.time
        ))

        // Insert one entry per future prayer transition
        for i in 0..<prayers.count {
            let current = prayers[i]
            let next    = prayers[(i + 1) % prayers.count]

            guard let currentPrayerDate = makeDate(from: current.timeStr, timeFmt, calendar) else { continue }
            guard currentPrayerDate > currentDate else { continue }

            entries.append(PrayerComplicationEntry(
                date: currentPrayerDate,
                nextPrayerName: next.name,
                nextPrayerTime: next.timeStr
            ))
        }

        return entries
    }
    
    // Helper function to load prayer times from shared UserDefaults
    private func loadPrayerTimesFromSharedDefaults() -> PrayerTimesResponse? {
        
        if let sharedDefaults = UserDefaults(suiteName: "group.com.AthanPlusCompanion"),
           let data = sharedDefaults.data(forKey: "prayerTimes") {
            do {
                let prayerTimes = try JSONDecoder().decode(PrayerTimesResponse.self, from: data)
                return prayerTimes
            } catch {
                return nil
            }
        }
        return nil
    }
    
    // Shared formatters — built once, reused everywhere
    
    // Date formatter for parsing the "date" field in each Iqamah entry (e.g. "2024-09-15")
    private func makeDateFormatter() -> DateFormatter {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "EEEE, MMMM d, yyyy"
        fmt.timeZone = TimeZone(identifier: "America/New_York")
        return fmt
    }

    // Time-only formatter matching the formatted output from PrayerTimesModel (e.g. "5:30 AM")
    private func makeTimeFormatter() -> DateFormatter {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "h:mm a"
        fmt.timeZone = TimeZone(identifier: "America/New_York")
        return fmt
    }
    
    // Helper function to parse today's prayer times into full Date objects anchored to today's calendar date
    // so comparisons agaisnt 'currentDate' are accurate across midnight boundaries
    private func makeDate(from timeString: String, _ timeFmt: DateFormatter, _ calendar: Calendar) -> Date? {
        guard let timeParsed = timeFmt.date(from: timeString) else { return nil }
        
        let timeCmpts = calendar.dateComponents([.hour, .minute], from: timeParsed)
        
        return calendar.date(
            bySettingHour: timeCmpts.hour ?? 0,
            minute: timeCmpts.minute ?? 0,
            second: 0,
            of:Date()
        )
    }
    
    // Function to get the next prayer time
    func getNextPrayerTime(from prayerTimes: PrayerTimesResponse) -> (name: String, time: String) {
        let currentDate = Date()
        let calendar = Calendar.current
        let dateFmt = makeDateFormatter()
        let timeFmt = makeTimeFormatter()
        
        // Today's date string so we can locate today's and tomorrow's Iqamah entries
        let todayString = dateFmt.string(from: currentDate)
        
        // Find today's Iqamah entry
        guard let todayIqamah = prayerTimes.data.iqamah.first(where: { $0.date == todayString }) else {
            // Fallback: no matching entry for today, return first available Fajr
            return (name: "G1", time: "0:00 AM")
            // return (name: "Fajr", time: prayerTimes.data.iqamah.first?.fajr ?? "")
        }
        
        guard
            let fajrDate = makeDate(from: todayIqamah.fajr, timeFmt, calendar),
            let zuhrDate = makeDate(from: todayIqamah.zuhr, timeFmt, calendar),
            let asrDate = makeDate(from: todayIqamah.asr, timeFmt, calendar),
            let maghribDate = makeDate(from: todayIqamah.maghrib, timeFmt, calendar),
            let ishaDate = makeDate(from: todayIqamah.isha, timeFmt, calendar)
        else {
            return (name: "G2", time: "2:00 AM")
//            return (name: "Fajr", time: todayIqamah.fajr)
        }

        
        // Determine which prayer comes next
        if currentDate < fajrDate {
            return (name: "Fajr", time: todayIqamah.fajr)
        }
        else if currentDate < zuhrDate {
            return (name: "Zuhr", time: todayIqamah.zuhr)
        }
        else if currentDate < asrDate {
            return (name: "Asr", time: todayIqamah.asr)
        }
        else if currentDate < maghribDate {
            return (name: "Maghrib", time: todayIqamah.maghrib)
        }
        else if currentDate < ishaDate {
            return (name: "Isha", time: todayIqamah.isha)
        }
        else {
            // past Isha - look up tomorrow's Fajr
            let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            let tomorrowString = dateFmt.string(from: tomorrowDate)
            
            if let tomorrowIqamah = prayerTimes.data.iqamah.first(where: { $0.date == tomorrowString }) {
//                return (name: "Ftmw", time: "3:00 AM")
                return (name: "Fajr", time: tomorrowIqamah.fajr)
            }
            else {
                // Tomorrow's data isn't in the cache range - fall back to today's Fajr as a placeholder
//                return (name: "Ftod", time: "4:00 AM")
                return (name: "Fajr", time: todayIqamah.fajr)
            }
        }
    }
}

struct PrayerComplicationView : View {
    var entry: PrayerComplicationEntry

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.23))
            VStack {
                Text(entry.nextPrayerName)
                    .font(.system(size: 12))
                    .bold()
                Text(entry.nextPrayerTime)
                    .font(.system(size: 11))
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
