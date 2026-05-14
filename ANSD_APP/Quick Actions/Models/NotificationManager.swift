//
//  NotificationManager.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 22/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // 1. Request Permission
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { print("Notifications allowed") } else { print("Notifications denied") }
        }
    }

    // 2. Schedule Notification (Now accepts an ID)
    func scheduleNotification(identifier: String, title: String, body: String, for date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Use the specific Item ID so we don't create duplicates
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("Error: \(error)") } else { print("Scheduled '\(title)' for \(date)") }
        }
    }

    // 3. Cancel Notification (Call this when deleting an item)
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled notification: \(identifier)")
    }

    // 4. Foreground Handling
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) { completionHandler([.banner, .sound, .list]) } else { completionHandler([.alert, .sound]) }
    }
}
