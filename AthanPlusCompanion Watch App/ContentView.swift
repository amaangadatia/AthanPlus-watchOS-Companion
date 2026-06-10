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
            VStack(spacing: 15) {

                // Date header — shows the date of the currently loaded
                // prayer data so you can confirm it's up to date
                Text(prayerTimeModel.prayerTimes.data.iqamah.first?.date ?? "No date")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)

                // Table header
                HStack {
                    Text("Prayer")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Iqamah")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Table rows
                ForEach(prayerTimeModel.prayerTimes.data.iqamah, id: \.date) { iqamah in
                    rowView(prayer: "Fajr",    time: iqamah.fajr)
                    rowView(prayer: "Zuhr",    time: iqamah.zuhr)
                    rowView(prayer: "Asr",     time: iqamah.asr)
                    rowView(prayer: "Maghrib", time: iqamah.maghrib)
                    rowView(prayer: "Isha",    time: iqamah.isha)
                }
            }
            .padding(.horizontal)
        }
        .ignoresSafeArea()
    }
    
    func rowView(prayer: String, time: String) -> some View {
        HStack {
            Text(prayer)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(time)
                .fixedSize()
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    ContentView()
}
