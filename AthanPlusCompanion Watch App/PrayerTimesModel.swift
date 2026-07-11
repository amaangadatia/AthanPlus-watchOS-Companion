//
//  PrayerTimesModel.swift
//  AthanPlusCompanion Watch App
//
//  Created by Amaan Gadatia on 9/9/24.
//

import Foundation
import SwiftUI

// Main struct for the response
struct PrayerTimesResponse: Codable {
    let status: String
    var data: SalahData
    let message: [String]
}

// Struct for the data section
struct SalahData: Codable {
    var salah: [Salah]
    var iqamah: [Iqamah]
}

// Struct for Salah times
struct Salah: Codable {
    let date: String
    let hijriDate: String
    let hijriMonth: String
    let day: String
    var fajr: String
    let sunrise: String
    var zuhr: String
    var asr: String
    var maghrib: String
    var isha: String
    
    enum CodingKeys: String, CodingKey {
        case date, hijriDate = "hijri_date", hijriMonth = "hijri_month", day, fajr, sunrise, zuhr, asr, maghrib, isha
    }
}

// Struct for Iqamah times
struct Iqamah: Codable {
    let date: String
    var fajr: String
    var zuhr: String
    var asr: String
    var maghrib: String
    var isha: String
    let jummah1: String
    let jummah2: String
    
    enum CodingKeys: String, CodingKey {
        case date, fajr, zuhr, asr, maghrib, isha, jummah1 = "jummah1", jummah2 = "jummah2"
    }
}

@MainActor
class PrayerTimesModel: ObservableObject {
    @Published var prayerTimes: PrayerTimesResponse = PrayerTimesResponse(
        status: "Unknown",
        data: SalahData(
            salah: [Salah(date: "", hijriDate: "", hijriMonth: "", day: "", fajr: "", sunrise: "", zuhr: "", asr: "", maghrib: "", isha: "")],
            iqamah: [Iqamah(date: "", fajr: "", zuhr: "", asr: "", maghrib: "", isha: "", jummah1: "", jummah2: "")]),
        message: ["No data available"]
    )
    
    // Fetches the local mosque's prayer timings for today via an API call and updates the watch app UI
    // The complication fetches independently via WidgetKit - this
    // only exists to keep ContentView in sync.
    func fetch() {
        if let decoded = readBestMatch(), !isStale(decoded) {
            // Fresh data already in UserDefaults - use it immediately
            self.prayerTimes = decoded
            print("DEBUG fetch() - fresh data: \(decoded.data.iqamah.first?.date ?? "?")")
        }
        else {
            // Data is stale - the widget's two day timeline means getTimeline
            // was already called before or around midnight and fresh data will
            // be in UserDefaults shortly. Poll until it appears
            if let decoded = readBestMatch() {
                self.prayerTimes = decoded
                print("DEBUG fetch() - showing stale data while polling UserDefaults: \(decoded.data.iqamah.first?.date ?? "?")")
            }
            retryFetch(attempts: 20, delay: 3.0)
            
        }
    }
    
    // Retries reading UserDefaults every 'delay' seconds up to 'attempts'
    // times. Stops as soon as fresh data for today appears.
    // 20 attempts * 3 seconds = 60 second window total.
    private func retryFetch(attempts: Int, delay: Double) {
        guard attempts > 0 else {
            print("DEBUG retryFetch() - gave up, widget hasn't written fresh data yet")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            if let decoded = self.readBestMatch(), !self.isStale(decoded) {
                self.prayerTimes = decoded
                print("DEBUG retryFetch() - fresh data loaded: \(decoded.data.iqamah.first?.date ?? "?")")
            }
            else {
                print("DEBUG retryFetch() - still stale, \(attempts - 1) attempts remaining")
                self.retryFetch(attempts: attempts - 1, delay: delay)
            }
            
        }
    }
    
    // Checks both the "today" and "tomorrow" caches written by the widget
    // and returns whichever one matches today's actual date. This means
    // the watch app can show the new day's data immediately after midnight
    // using the "tomorrow" cache from the previous night's getTimeline call,
    // without waiting for a new getTimeline call after midnight.
    private func readBestMatch() -> PrayerTimesResponse? {
        let todayCandidate = readFromUserDefaults(key: "prayerTimes")
        let tmrwCandidate = readFromUserDefaults(key: "prayerTimesTmrw")
        
        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "en_US_POSIX")
        dateFmt.dateFormat = "EEEE, MMM d, yyyy"
        dateFmt.timeZone = TimeZone(identifier: "America/New_York")
        let todayString = dateFmt.string(from: Date())
        
        if let todayCandidate, todayCandidate.data.iqamah.first?.date == todayString {
            return todayCandidate
        }
        if let tmrwCandidate, tmrwCandidate.data.iqamah.first?.date == todayString {
            return tmrwCandidate
        }
        
        // Neither matches today - return today's cache as a fallback
        return todayCandidate ?? tmrwCandidate
    }
    
    private func readFromUserDefaults(key: String) -> PrayerTimesResponse? {
        guard
            let defaults = UserDefaults(suiteName: "group.com.AthanPlusCompanion"),
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(PrayerTimesResponse.self, from: data)
        else { return nil }
        
        return decoded
    }
    
    // Returns true if the cached data is from a previous day
    private func isStale(_ response: PrayerTimesResponse) -> Bool {
        guard let firstIqamah = response.data.iqamah.first else { return true }
        
        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "en_US_POSIX")
        dateFmt.dateFormat = "EEEE, MMM d, yyyy"
        dateFmt.timeZone = TimeZone(identifier: "America/New_York")
        return firstIqamah.date != dateFmt.string(from: Date())
    }
}
