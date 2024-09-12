//
//  ExtensionDelegate.swift
//  AthanPlusCompanion Watch App
//
//  Created by Amaan Gadatia on 9/10/24.
//

import Foundation
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let refreshTask = task as? WKApplicationRefreshBackgroundTask {
                PrayerTimesModel().fetch()
                
                refreshTask.setTaskCompletedWithSnapshot(true)
            }
            else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
