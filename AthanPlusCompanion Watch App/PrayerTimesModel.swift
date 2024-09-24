//
//  PrayerTimesModel.swift
//  AthanPlusCompanion Watch App
//
//  Created by Amaan Gadatia on 9/9/24.
//

import Foundation
import SwiftUI
//import WatchKit

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
    
    // fetches the local mosque's prayer timings via an API call
    func fetch() async {
        guard let url = URL(string: "https://masjidal.com/api/v1/time/range?masjid_id=3OA87VLp") else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Convert to JSON
            var fetchedPrayerTimes = try JSONDecoder().decode(PrayerTimesResponse.self, from: data)

            // Format times for each salah and iqamah entry
            for index in fetchedPrayerTimes.data.salah.indices {
                fetchedPrayerTimes.data.salah[index].fajr = formatTime(fetchedPrayerTimes.data.salah[index].fajr) ?? fetchedPrayerTimes.data.salah[index].fajr
                fetchedPrayerTimes.data.salah[index].zuhr = formatTime(fetchedPrayerTimes.data.salah[index].zuhr) ?? fetchedPrayerTimes.data.salah[index].zuhr
                fetchedPrayerTimes.data.salah[index].asr = formatTime(fetchedPrayerTimes.data.salah[index].asr) ?? fetchedPrayerTimes.data.salah[index].asr
                fetchedPrayerTimes.data.salah[index].maghrib = formatTime(fetchedPrayerTimes.data.salah[index].maghrib) ?? fetchedPrayerTimes.data.salah[index].maghrib
                fetchedPrayerTimes.data.salah[index].isha = formatTime(fetchedPrayerTimes.data.salah[index].isha) ?? fetchedPrayerTimes.data.salah[index].isha
            }

            for index in fetchedPrayerTimes.data.iqamah.indices {
                fetchedPrayerTimes.data.iqamah[index].fajr = formatTime(fetchedPrayerTimes.data.iqamah[index].fajr) ?? fetchedPrayerTimes.data.iqamah[index].fajr
                fetchedPrayerTimes.data.iqamah[index].zuhr = formatTime(fetchedPrayerTimes.data.iqamah[index].zuhr) ?? fetchedPrayerTimes.data.iqamah[index].zuhr
                fetchedPrayerTimes.data.iqamah[index].asr = formatTime(fetchedPrayerTimes.data.iqamah[index].asr) ?? fetchedPrayerTimes.data.iqamah[index].asr
                fetchedPrayerTimes.data.iqamah[index].maghrib = formatTime(fetchedPrayerTimes.data.iqamah[index].maghrib) ?? fetchedPrayerTimes.data.iqamah[index].maghrib
                fetchedPrayerTimes.data.iqamah[index].isha = formatTime(fetchedPrayerTimes.data.iqamah[index].isha) ?? fetchedPrayerTimes.data.iqamah[index].isha
            }

            // Update the prayerTimes on the main thread safely
            self.prayerTimes = fetchedPrayerTimes
        } catch {
            print(error)
        }
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
}
