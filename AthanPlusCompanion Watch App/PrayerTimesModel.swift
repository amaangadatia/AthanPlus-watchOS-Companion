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
        guard
            let defaults = UserDefaults(suiteName: "group.com.AthanPlusCompanion"),
            let data = defaults.data(forKey: "prayerTimes"),
            let decoded = try? JSONDecoder().decode(PrayerTimesResponse.self, from: data)
        else {
            print("DEBUG PrayerTimesModel.fetch() - no data in UserDefaults yet")
            return
        }
        
        self.prayerTimes = decoded
    }
}
