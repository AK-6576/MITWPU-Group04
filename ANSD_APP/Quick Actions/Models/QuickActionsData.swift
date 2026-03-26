//
//  QuickActionsData.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

// MARK: - Quick Actions Repository
// Singleton class responsible for managing persistent storage and retrieval of quick action items.
class QuickActionsRepository {
    
    static let shared = QuickActionsRepository()

    private var quickActionBubbles: [RoutineConversation] = []
    private var isSyncingFromFirebase = false

    private init() {
        loadFromDisk()
        startObservingSharedActions()
    }
    
    // MARK: - Firebase Sync
    func startObservingSharedActions() {
        // Use the saved first name to look up shared actions by name
        guard let firstName = UserDefaults.standard.string(forKey: "user_first_name") else {
            print("QuickActionsData: user_first_name not found yet. Cannot observe shared actions.")
            return
        }
        
        FirebaseManager.shared.observeSharedQuickActions(forUserName: firstName) { [weak self] dict in
            self?.handleIncomingAction(dict)
        }
        
        // Also observe by full name, since contacts often use First + Last name
        let lastName = UserDefaults.standard.string(forKey: "user_last_name") ?? ""
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        if fullName != firstName && !fullName.isEmpty {
            FirebaseManager.shared.observeSharedQuickActions(forUserName: fullName) { [weak self] dict in
                self?.handleIncomingAction(dict)
            }
        }
        
        // Also observe the user's own quick_actions node (by UID)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let safeUID = FirebaseManager.shared.sanitizeKey(uid)
        let dbRef = Database.database(url: "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
        
        dbRef.child("users").child(safeUID).child("quick_actions").observe(.childAdded) { [weak self] snapshot in
            if let value = snapshot.value as? [String: Any] {
                self?.handleIncomingAction(value)
            }
        }
        
        dbRef.child("users").child(safeUID).child("quick_actions").observe(.childChanged) { [weak self] snapshot in
            if let value = snapshot.value as? [String: Any] {
                self?.handleIncomingAction(value)
            }
        }
    }
    
    private func handleIncomingAction(_ dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let categoryTitle = dict["categoryTitle"] as? String,
              let conversationTopic = dict["conversationTopic"] as? String,
              let startTime = dict["startTime"] as? String,
              let status = dict["status"] as? String,
              let roomCode = dict["roomCode"] as? String,
              let iconName = dict["iconName"] as? String,
              let topicImage = dict["topicImage"] as? String,
              let timeImage = dict["timeImage"] as? String,
              let date = dict["date"] as? String,
              let description = dict["description"] as? String,
              let participantNames = dict["participantNames"] as? [String] else {
            return
        }
        
        let hostUID = dict["hostUID"] as? String
        
        let action = RoutineConversation(
            id: id,
            iconName: iconName,
            categoryTitle: categoryTitle,
            status: status,
            conversationTopic: conversationTopic,
            topicImage: topicImage,
            startTime: startTime,
            description: description,
            date: date,
            timeImage: timeImage,
            roomCode: roomCode,
            participantNames: participantNames,
            hostUID: hostUID
        )
        
        // Check if already exists to prevent dupes
        if !self.quickActionBubbles.contains(where: { $0.id == action.id }) {
            self.quickActionBubbles.append(action)
            self.saveToDisk()
            self.notifyObservers()
            print("QuickActionsData: Received shared Quick Action '\(action.conversationTopic)'")
        } else {
            // Update locally ONLY — do NOT sync back to Firebase to avoid infinite loop
            if let index = self.quickActionBubbles.firstIndex(where: { $0.id == action.id }) {
                self.quickActionBubbles[index] = action
                self.saveToDisk()
                self.notifyObservers()
            }
        }
    }
    
    // MARK: - Data Access Methods
    func getGroupedSections() -> [RoutineSection] {
        let groupedDictionary = Dictionary(grouping: quickActionBubbles) { $0.categoryTitle }
        
        return groupedDictionary.map { (key, value) in
            let sortedItems = value.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
            return RoutineSection(category: key, items: sortedItems)
        }.sorted { $0.category < $1.category }
    }

    func getAllActions() -> [RoutineConversation] {
        return quickActionBubbles.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
    }
    
    /// MVC Refactor: Provides the top-N upcoming actions for the dashboard, filtered by a cutoff time.
    func getUpcomingActions(limit: Int = 3) -> [RoutineConversation] {
        let cutoffTime = Date().addingTimeInterval(-1800) // 30 mins ago
        
        let sortedFutureActions = quickActionBubbles.filter { item in
            guard item.status != "Done", let itemDate = getDate(from: item.startTime) else { return false }
            return itemDate > cutoffTime
        }.sorted { (item1, item2) -> Bool in
            guard let date1 = getDate(from: item1.startTime),
                  let date2 = getDate(from: item2.startTime) else { return false }
            return date1 < date2
        }
        
        return Array(sortedFutureActions.prefix(limit))
    }
    
    func addAction(_ action: RoutineConversation) {
        quickActionBubbles.append(action)
        saveToDisk()
        notifyObservers()
        syncToFirebase(action)
        scheduleNotifications(for: action)
    }

    func deleteAction(_ action: RoutineConversation) {
        // 1. Delete from Firebase
        let codeToDelete = action.roomCode ?? action.id
        FirebaseManager.shared.deleteQuickAction(roomCode: codeToDelete)
        
        // 2. Delete from Local
        self.quickActionBubbles.removeAll { $0.id == action.id }
        NotificationManager.shared.cancelNotification(identifier: "qa_\(action.id)_exact")
        NotificationManager.shared.cancelNotification(identifier: "qa_\(action.id)_5min")
        saveToDisk()
        notifyObservers()
    }

    func updateAction(_ action: RoutineConversation) {
        if let index = self.quickActionBubbles.firstIndex(where: { $0.id == action.id }) {
            self.quickActionBubbles[index] = action
            saveToDisk()
            notifyObservers()
            syncToFirebase(action)
            scheduleNotifications(for: action)
        }
    }
    
    // Completely wipes all locally stored Quick Actions (used on logout)
    func clearAllActions() {
        for action in self.quickActionBubbles {
            NotificationManager.shared.cancelNotification(identifier: "qa_\(action.id)_exact")
            NotificationManager.shared.cancelNotification(identifier: "qa_\(action.id)_5min")
        }
        self.quickActionBubbles.removeAll()
        saveToDisk()
        notifyObservers()
    }
    
    private func syncToFirebase(_ action: RoutineConversation) {
        // Guard: don't write back to Firebase if we're processing incoming Firebase data
        guard !isSyncingFromFirebase else { return }
        
        let hostID: String
        if let existingHost = action.hostUID {
            hostID = existingHost
        } else {
            let rawID = Auth.auth().currentUser?.uid ?? "UnknownUser"
            hostID = FirebaseManager.shared.sanitizeKey(rawID)
        }
        
        if action.roomCode != nil {
            FirebaseManager.shared.saveQuickActionMetadata(action, hostUID: hostID)
        }
    }
    
    // MARK: - Notification Logic
    private func scheduleNotifications(for action: RoutineConversation) {
        guard let dateString = action.date, !dateString.isEmpty else { return }
        
        // Combine date and time
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Assumes date is like "Mon, Dec 15" and time is "2:30 PM". We need a reliable date parsing.
        // For simplicity and to match the current app's loose date strings, we'll try to parse it.
        // If the date string does not contain an exact year, this might fail, but let's assume we can build Date.
        formatter.dateFormat = "EEE, MMM d yyyy h:mm a"
        
        // Fallback: Just parse time for today if date parsing is too complex or missing year.
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "h:mm a"
        
        var targetDate: Date?
        
        if let fullDate = formatter.date(from: "\(dateString) 2026 \(action.startTime)") { // Hardcoding year for demo if needed, but better to use current year
             targetDate = fullDate
        } else if let timeDate = timeFormatter.date(from: action.startTime) {
             // Use today's date with parsed time
             let now = Date()
             let calendar = Calendar.current
             var components = calendar.dateComponents([.year, .month, .day], from: now)
             let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
             components.hour = timeComponents.hour
             components.minute = timeComponents.minute
             targetDate = calendar.date(from: components)
             
             // If time has already passed today, schedule for tomorrow
             if let t = targetDate, t < now {
                 targetDate = calendar.date(byAdding: .day, value: 1, to: t)
             }
        }
        
        guard let finalDate = targetDate, finalDate > Date() else {
            print("QuickActionsData: Cannot schedule notification in the past for \(action.conversationTopic)")
            return
        }
        
        // 1. Exact Time Notification
        NotificationManager.shared.scheduleNotification(
            identifier: "qa_\(action.id)_exact",
            title: "Quick Action Starting Now",
            body: "Join your room: \(action.conversationTopic) (\(action.categoryTitle))",
            for: finalDate
        )
        
        // 2. 5 Minutes Prior Notification
        if let fiveMinsBefore = Calendar.current.date(byAdding: .minute, value: -5, to: finalDate), fiveMinsBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                identifier: "qa_\(action.id)_5min",
                title: "Quick Action in 5 Minutes",
                body: "Get ready for: \(action.conversationTopic) (\(action.categoryTitle))",
                for: fiveMinsBefore
            )
        }
    }
    
    // MARK: - Persistence Logic
    
    /// UID-scoped key for UserDefaults storage
    private var storageKey: String {
        let uid = Auth.auth().currentUser?.uid ?? "unknown"
        return "saved_quick_actions_\(uid)"
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(quickActionBubbles)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("QuickActionsRepository: Failed to save data. Error: \(error)")
        }
    }
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                quickActionBubbles = try JSONDecoder().decode([RoutineConversation].self, from: data)
                print("QuickActionsRepository: Successfully loaded \(quickActionBubbles.count) actions.")
            } catch {
                print("QuickActionsRepository: Failed to load data. Error: \(error)")
            }
        }
    }
    
    private func notifyObservers() {
        NotificationCenter.default.post(name: NSNotification.Name("ActionsUpdated"), object: nil)
    }
    
    private func compareTimes(time1: String, time2: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let d1 = formatter.date(from: time1),
              let d2 = formatter.date(from: time2) else { return false }
        return d1 < d2
    }
}
