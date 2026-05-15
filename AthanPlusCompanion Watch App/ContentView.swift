//
//  ContentView.swift
//  AthanPlusCompanion Watch App
//
//  Created by Amaan Gadatia on 9/9/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var prayerTimeModel: PrayerTimesModel
    
    var body: some View {
        List {
            VStack {
                VStack(spacing: 15) {
                    // Table Header
                    HStack {
                        Text("Prayer")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading) // Align to the left
                        Text("Iqamah")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .trailing) // Align to the right
                    }
                    .padding()
                    
                    // Table Rows (5 prayers)
                    ForEach(prayerTimeModel.prayerTimes.data.iqamah, id: \.date) { iqamah in
                        rowView(prayer: "Fajr", time: iqamah.fajr)
                        rowView(prayer: "Zuhr", time: iqamah.zuhr)
                        rowView(prayer: "Asr", time: iqamah.asr)
                        rowView(prayer: "Maghrib", time: iqamah.maghrib)
                        rowView(prayer: "Isha", time: iqamah.isha)
                    }
                }
                .padding()
            }
            .padding()
        }
        .edgesIgnoringSafeArea(.top)
        .task {
            await prayerTimeModel.fetch()
        }
    }
    
    func rowView(prayer: String, time: String) -> some View {
        HStack {
            Text(prayer)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(time)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    ContentView()
}
