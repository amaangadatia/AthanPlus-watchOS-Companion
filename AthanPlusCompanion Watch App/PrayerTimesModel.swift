//
//  PrayerTimesModel.swift
//  AthanPlusCompanion Watch App
//
//  Created by Amaan Gadatia on 9/9/24.
//

import Foundation
import SwiftUI
import WatchKit

// Struct for Salah times
struct Salah: Codable {
    let date: String
    let hijriDate: String
    let hijriMonth: String
    let day: String
    let fajr: String
    let sunrise: String
    let zuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    
    enum CodingKeys: String, CodingKey {
        case date, hijriDate = "hijri_date", hijriMonth = "hijri_month", day, fajr, sunrise, zuhr, asr, maghrib, isha
    }
}

// Struct for Iqamah times
struct Iqamah: Codable {
    let date: String
    let fajr: String
    let zuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let jummah1: String
    let jummah2: String
    
    enum CodingKeys: String, CodingKey {
        case date, fajr, zuhr, asr, maghrib, isha, jummah1 = "jummah1", jummah2 = "jummah2"
    }
}

// Struct for the data section
struct SalahData: Codable {
    let salah: [Salah]
    let iqamah: [Iqamah]
}

// Main struct for the response
struct PrayerTimesResponse: Codable {
    let status: String
    let data: SalahData
    let message: [String]
}

class PrayerTimesModel: ObservableObject {
    @Published var prayerTimes: PrayerTimesResponse = PrayerTimesResponse(
        status: "Unknown",
        data: SalahData(
            salah: [Salah(date: "", hijriDate: "", hijriMonth: "", day: "", fajr: "", sunrise: "", zuhr: "", asr: "", maghrib: "", isha: "")],
            iqamah: [Iqamah(date: "", fajr: "", zuhr: "", asr: "", maghrib: "", isha: "", jummah1: "", jummah2: "")]),
        message: ["No data available"]
    )
    
    func fetch() {
        guard let url = URL(string: "https://masjidal.com/api/v1/time/range?masjid_id=3OA87VLp") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                return
            }
            
            // Convert to JSON
            do {
                let prayerTimes = try JSONDecoder().decode(PrayerTimesResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.prayerTimes = prayerTimes
                }
            }
            catch {
                print(error)
            }
        }
        task.resume()
    }
    
    // Schedule the next background refresh
    func scheduleNextBackgroundRefresh() {
        let calendar = Calendar.current
        var dateCmpts = DateComponents()
        dateCmpts.hour = 10
        dateCmpts.minute = 0
//        let nextUpdateDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        if let preferredDate = calendar.nextDate(after: Date(), matching: dateCmpts, matchingPolicy: .nextTime) {
            WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: preferredDate, userInfo: nil) { error in
                if let error = error {
                    print("Error scheduling background refresh: \(error)")
                }
                else {
                    print("Background refresh scheduled for: \(preferredDate)")
                }
            }
        }
    }
}
