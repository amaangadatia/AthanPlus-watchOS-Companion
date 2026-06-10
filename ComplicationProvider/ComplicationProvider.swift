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
    
    private let masjidID = "3OA87VLp"
    
    func placeholder(in context: Context) -> PrayerComplicationEntry {
        PrayerComplicationEntry(date: Date(), nextPrayerName: "Fajr", nextPrayerTime: "5:00AM")
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerComplicationEntry) -> ()) {
        let entry = PrayerComplicationEntry(date: Date(), nextPrayerName: "Fajr", nextPrayerTime: "5:00AM")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerComplicationEntry>) -> ()) {
        Task {
            let now = Date()
            let easternCalendar = makeEasternCalendar()

            async let todayResponse = fetchPrayerTimes(for: Date())
            async let tomorrowResponse = fetchPrayerTimes(
                for: easternCalendar.date(byAdding: .day, value: 1, to: now) ?? now
            )

            let (today, tomorrow) = await (todayResponse, tomorrowResponse)

            if let today = today {
                savePrayerTimesToSharedDefaults(prayerTimes: today)
            }

            let entries = buildTimelineEntries(today: today, tomorrow: tomorrow)

            let dayAfterTmrw = easternCalendar.startOfDay(
                for: easternCalendar.date(byAdding: .day, value: 2, to: now) ?? now
            )
            
//            let parts = tomorrow?.data.iqamah.first?.isha.split(separator: " ")
//            if let time = parts.first {
//                let hours = time.first!
//                let start = time.index(time.startIndex, offsetBy: 2)
//                let end = time.index(time.startIndex, offsetBy: 4)
//                let substring = time[start..<end]
//                let minutes = String(substring)
//            }
            
            
            let refreshDate = dayAfterTmrw.addingTimeInterval(-120)

            let timeline = Timeline(entries: entries, policy: .after(refreshDate))
            completion(timeline)
        }
    }
    
    // MARK: - API Fetch
    
    private func fetchPrayerTimes(for date: Date) async -> PrayerTimesResponse? {
        let apiDateFmt = DateFormatter()
        apiDateFmt.locale = Locale(identifier: "en_US_POSIX")
        apiDateFmt.dateFormat = "yyyy-MM-dd"
        apiDateFmt.timeZone = TimeZone(identifier: "America/New_York")
        let dateString = apiDateFmt.string(from: date)
        
        let url = "https://masjidal.com/api/v1/time/range?masjid_id=\(masjidID)&from_date=\(dateString)&to_date=\(dateString)"
        guard let url = URL(string: url) else { return nil }
        
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Convert to JSON
            var fetchedPrayerTimes = try JSONDecoder().decode(PrayerTimesResponse.self, from: data)
            
            // Format times for each salah and iqamah entry
            for i in fetchedPrayerTimes.data.salah.indices {
                fetchedPrayerTimes.data.salah[i].fajr = formatTime(fetchedPrayerTimes.data.salah[i].fajr) ?? fetchedPrayerTimes.data.salah[i].fajr
                fetchedPrayerTimes.data.salah[i].zuhr = formatTime(fetchedPrayerTimes.data.salah[i].zuhr) ?? fetchedPrayerTimes.data.salah[i].zuhr
                fetchedPrayerTimes.data.salah[i].asr = formatTime(fetchedPrayerTimes.data.salah[i].asr) ?? fetchedPrayerTimes.data.salah[i].asr
                fetchedPrayerTimes.data.salah[i].maghrib = formatTime(fetchedPrayerTimes.data.salah[i].maghrib) ?? fetchedPrayerTimes.data.salah[i].maghrib
                fetchedPrayerTimes.data.salah[i].isha = formatTime(fetchedPrayerTimes.data.salah[i].isha) ?? fetchedPrayerTimes.data.salah[i].isha
            }
            
            for i in fetchedPrayerTimes.data.iqamah.indices {
                fetchedPrayerTimes.data.iqamah[i].fajr = formatTime(fetchedPrayerTimes.data.iqamah[i].fajr) ?? fetchedPrayerTimes.data.iqamah[i].fajr
                fetchedPrayerTimes.data.iqamah[i].zuhr = formatTime(fetchedPrayerTimes.data.iqamah[i].zuhr) ?? fetchedPrayerTimes.data.iqamah[i].zuhr
                fetchedPrayerTimes.data.iqamah[i].asr = formatTime(fetchedPrayerTimes.data.iqamah[i].asr) ?? fetchedPrayerTimes.data.iqamah[i].asr
                fetchedPrayerTimes.data.iqamah[i].maghrib = formatTime(fetchedPrayerTimes.data.iqamah[i].maghrib) ?? fetchedPrayerTimes.data.iqamah[i].maghrib
                fetchedPrayerTimes.data.iqamah[i].isha = formatTime(fetchedPrayerTimes.data.iqamah[i].isha) ?? fetchedPrayerTimes.data.iqamah[i].isha
            }
            
            return fetchedPrayerTimes
        } catch {
            print("DEBUG fetchPrayerTimes() error for \(dateString): \(error)")
            return nil
        }
    }
    
    // MARK: - Timeline Building
    
    private func buildTimelineEntries(today: PrayerTimesResponse?, tomorrow: PrayerTimesResponse?) -> [PrayerComplicationEntry] {
        let currentDate = Date()
        let calendar = makeEasternCalendar()
        let dateFmt = makeDateFormatter()
        let timeFmt = makeTimeFormatter()
        let todayString = dateFmt.string(from: currentDate)

        guard let today,
              let todayIqamah = today.data.iqamah.first(where: { $0.date == todayString })
        else {
            // No data at all - show placeholder and retry in 15 mins
            print("DEBUG buildTimelineEntries fallback hit")
            print("DEBUG todayString: '\(todayString)'")
            print("DEBUG available iqamah dates: \(today?.data.iqamah.map { $0.date } ?? [])")
            return [PrayerComplicationEntry(date: currentDate, nextPrayerName: "Fajr", nextPrayerTime: "-")]
        }

        let prayers: [(name: String, timeStr: String)] = [
            ("Fajr",    todayIqamah.fajr),
            ("Zuhr",    todayIqamah.zuhr),
            ("Asr",     todayIqamah.asr),
            ("Maghrib", todayIqamah.maghrib),
            ("Isha",    todayIqamah.isha)
        ]

        // Tomorrow's Fajr - use fetched data if available, else fallback to today's Fajr
        let tomorrowFajr = tomorrow?.data.iqamah.first?.fajr ?? todayIqamah.fajr
        
        var entries: [PrayerComplicationEntry] = []

        // Insert immediate entry for right now
        let currentNextPrayer = getNextPrayerTime(
            todayIqamah: todayIqamah,
            tomorrowFajr: tomorrowFajr,
            currentDate: currentDate,
            timeFmt: timeFmt,
            calendar: calendar
        )
        entries.append(PrayerComplicationEntry(
            date: currentDate,
            nextPrayerName: currentNextPrayer.name,
            nextPrayerTime: currentNextPrayer.time
        ))

        // Insert one entry per future prayer transition
        for i in 0..<prayers.count {
            let current = prayers[i]
            
            guard let currentPrayerDate = makeDate(from: current.timeStr, timeFmt, calendar) else { continue }
            guard currentPrayerDate > currentDate else { continue }
            
            // After Isha, show tomorrow's Fajr
            let nextName: String
            let nextTime: String
            
            if current.name == "Isha" {
                nextName = "Fajr"
                nextTime = tomorrowFajr
            }
            else {
                let next = prayers[(i + 1) % prayers.count]
                nextName = next.name
                nextTime = next.timeStr
            }
        
            entries.append(PrayerComplicationEntry(
                date: currentPrayerDate,
                nextPrayerName: nextName,
                nextPrayerTime: nextTime
            ))
        }
        
        // Add an explicit midnight entry showing tomorrow's Fajr.
        // This bridges the gap between the Isha entry and when getTimeline
        // fires again after midnight, preventing "Fajr -" placeholder from appearing.
        let tmrwMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate)
        if tmrwMidnight > currentDate {
            entries.append(PrayerComplicationEntry(date: tmrwMidnight, nextPrayerName: "Fajr", nextPrayerTime: tomorrowFajr))
        }

        return entries
    }
    
    // Function to get the next prayer time
    func getNextPrayerTime(
        todayIqamah: Iqamah,
        tomorrowFajr: String,
        currentDate: Date,
        timeFmt: DateFormatter,
        calendar: Calendar
    ) -> (name: String, time: String) {
        
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
        if      currentDate < fajrDate      { return (name: "Fajr", time: todayIqamah.fajr) }
        else if currentDate < zuhrDate      { return (name: "Zuhr", time: todayIqamah.zuhr) }
        else if currentDate < asrDate       { return (name: "Asr", time: todayIqamah.asr) }
        else if currentDate < maghribDate   { return (name: "Maghrib", time: todayIqamah.maghrib) }
        else if currentDate < ishaDate      { return (name: "Isha", time: todayIqamah.isha) }
        else                                { return (name: "Fajr", time: tomorrowFajr) }
    }
    
    // MARK: - Persistence
    
    // Keep UserDefaults in sync so the watch app UI reflects the latest data
    private func savePrayerTimesToSharedDefaults(prayerTimes: PrayerTimesResponse) {
        guard let defaults = UserDefaults(suiteName: "group.com.AthanPlusCompanion") else { return }
            do {
                let encodedPrayerTimes = try JSONEncoder().encode(prayerTimes)
                defaults.set(encodedPrayerTimes, forKey: "prayerTimes")
            }
            catch {
                print("Failed to encode prayer times: \(error)")
            }
    }
    
    // MARK: Shared formatters — built once, reused everywhere
    
    // Eastern time calendar - must be used for ALL date/time calculations
    // so that midnight, prayer transitions, and refresh times are anchored
    // to local Eastern time rather than UTC
    private func makeEasternCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }
    
    
    // Date formatter for parsing the "date" field in each Iqamah entry (e.g. "2024-09-15")
    private func makeDateFormatter() -> DateFormatter {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "EEEE, MMM d, yyyy"
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
            of: Date()
        )
    }
    
    // Reformats a raw API time string ("5:15AM") into display format ("5:15 AM")
    func formatTime(_ time: String) -> String? {
        let dateFormatter = DateFormatter()
        
        // Input format: time without space between time and AM/PM
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "h:mma"
        
        // Try to parse the input time
        if let date = dateFormatter.date(from: time) {
            // Output format: time with a space between time and AM/PM
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: date)
        }
        
        return nil // Return nil if the time format is invalid
    }
}

// MARK: - Views

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
