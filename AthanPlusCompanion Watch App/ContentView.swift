//
//  ContentView.swift
//  AthanPlusCompanion Watch App
//
//  Created by Amaan Gadatia on 9/9/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var prayerTimeModel = PrayerTimesModel()
    
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
                    HStack {
                        Text("Fajr")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(prayerTimeModel.prayerTimes.data.iqamah.first?.fajr ?? "")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Zuhr")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(prayerTimeModel.prayerTimes.data.iqamah.first?.zuhr ?? "")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Asr")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(prayerTimeModel.prayerTimes.data.iqamah.first?.asr ?? "")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Maghrib")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(prayerTimeModel.prayerTimes.data.iqamah.first?.maghrib ?? "")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Isha")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(prayerTimeModel.prayerTimes.data.iqamah.first?.isha ?? "")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding()
            }
            .padding()
            .onAppear {
                prayerTimeModel.fetch()
                prayerTimeModel.scheduleNextBackgroundRefresh()
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
}

#Preview {
    ContentView()
}
