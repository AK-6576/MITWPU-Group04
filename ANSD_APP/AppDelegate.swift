//
//  AppDelegate.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 05/1/26.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. Ask for Notification Permissions immediately on launch
        NotificationManager.shared.requestAuthorization()
        
        // 2. Set the delegate to handle foreground notifications
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}
