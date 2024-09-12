//
//  PrayerTimesModel.swift
//  AthanPlusCompanion Watch App
//
//  Created by Amaan Gadatia on 9/9/24.
//

import Foundation
import SwiftUI
import WatchKit

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


class PrayerTimesModel: ObservableObject {
    @Published var prayerTimes: PrayerTimesResponse = PrayerTimesResponse(
        status: "Unknown",
        data: SalahData(
            salah: [Salah(date: "", hijriDate: "", hijriMonth: "", day: "", fajr: "", sunrise: "", zuhr: "", asr: "", maghrib: "", isha: "")],
            iqamah: [Iqamah(date: "", fajr: "", zuhr: "", asr: "", maghrib: "", isha: "", jummah1: "", jummah2: "")]),
        message: ["No data available"]
    )
    
    // fetches the local mosque's prayer timings via an API call
    func fetch() {
        guard let url = URL(string: "https://masjidal.com/api/v1/time/range?masjid_id=3OA87VLp") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [self] data, _, error in
            guard let data = data, error == nil else {
                return
            }
            
            // Convert to JSON
            do {
                var prayerTimes = try JSONDecoder().decode(PrayerTimesResponse.self, from: data)
                
                // Format times for each salah and iqamah entry
                for index in prayerTimes.data.salah.indices {
                    prayerTimes.data.salah[index].fajr = formatTime(prayerTimes.data.salah[index].fajr) ?? prayerTimes.data.salah[index].fajr
                    prayerTimes.data.salah[index].zuhr = formatTime(prayerTimes.data.salah[index].zuhr) ?? prayerTimes.data.salah[index].zuhr
                    prayerTimes.data.salah[index].asr = formatTime(prayerTimes.data.salah[index].asr) ?? prayerTimes.data.salah[index].asr
                    prayerTimes.data.salah[index].maghrib = formatTime(prayerTimes.data.salah[index].maghrib) ?? prayerTimes.data.salah[index].maghrib
                    prayerTimes.data.salah[index].isha = formatTime(prayerTimes.data.salah[index].isha) ?? prayerTimes.data.salah[index].isha
                }
                
                for index in prayerTimes.data.iqamah.indices {
                    prayerTimes.data.iqamah[index].fajr = formatTime(prayerTimes.data.iqamah[index].fajr) ?? prayerTimes.data.iqamah[index].fajr
                    prayerTimes.data.iqamah[index].zuhr = formatTime(prayerTimes.data.iqamah[index].zuhr) ?? prayerTimes.data.iqamah[index].zuhr
                    prayerTimes.data.iqamah[index].asr = formatTime(prayerTimes.data.iqamah[index].asr) ?? prayerTimes.data.iqamah[index].asr
                    prayerTimes.data.iqamah[index].maghrib = formatTime(prayerTimes.data.iqamah[index].maghrib) ?? prayerTimes.data.iqamah[index].maghrib
                    prayerTimes.data.iqamah[index].isha = formatTime(prayerTimes.data.iqamah[index].isha) ?? prayerTimes.data.iqamah[index].isha
                }
                
                DispatchQueue.main.async {
                    self.prayerTimes = prayerTimes
                    self.savePrayerTimesToSharedDefaults(prayerTimes: prayerTimes)
                }
            }
            catch {
                print(error)
            }
        }
        task.resume()
    }
    
    // Helper function to reformat the time
    func formatTime(_ time: String) -> String? {
        let dateFormatter = DateFormatter()
        
        // Input format: time without space between time and AM/PM
        dateFormatter.dateFormat = "h:mma"
        
        // Try to parse the input time
        if let date = dateFormatter.date(from: time) {
            // Output format: time with a space between time and AM/PM
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: date)
        }
        
        return nil // Return nil if the time format is invalid
    }
    
    // Store the fetched prayer times in the shared UserDefaults
    private func savePrayerTimesToSharedDefaults(prayerTimes: PrayerTimesResponse) {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.AthanPlusCompanion") {
            do {
                let encodedPrayerTimes = try JSONEncoder().encode(prayerTimes)
                sharedDefaults.setValue(encodedPrayerTimes, forKey: "prayerTimes")
            }
            catch {
                print("Failed to encode prayer times: \(error)")
            }
        }
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
