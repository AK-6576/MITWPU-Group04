//
//  AppDelegate.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import FirebaseCore
import SwiftData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var sharedModelContainer: ModelContainer?

    // MARK: - Core Data Context
    // Global access point for the SwiftData persistent context, enabling database operations across the application.
    static var dbContext: ModelContext? {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return delegate.sharedModelContainer?.mainContext
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        do {
            sharedModelContainer = try ModelContainer(for: Conversation.self, Message.self, Participant.self)
            print("SwiftData: Successfully initialized the ModelContainer.")
        } catch {
            print("SwiftData: Failed to initialize ModelContainer. Error: \(error.localizedDescription)")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
