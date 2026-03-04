//
//  QuickActionsData.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation

// MARK: - Quick Actions Repository
// Singleton class responsible for managing persistent storage and retrieval of quick action items.
class QuickActionsRepository {
    
    static let shared = QuickActionsRepository()

    private var quickActionBubbles: [RoutineConversation] = []

    private var viewOnlyItems: [RoutineConversation] = []
    
    // Initializer loads existing data from disk to ensure persistence.
    private init() {
        loadFromDisk()
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
        let combined = quickActionBubbles + viewOnlyItems
        return combined.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
    }
    
    func addAction(_ action: RoutineConversation) {
        quickActionBubbles.append(action)
        saveToDisk()
        notifyObservers()
    }

    func deleteAction(_ action: RoutineConversation) {
        self.quickActionBubbles.removeAll { $0.id == action.id }
        saveToDisk()
        notifyObservers()
    }

    func updateAction(_ action: RoutineConversation) {
        if let index = self.quickActionBubbles.firstIndex(where: { $0.id == action.id }) {
            self.quickActionBubbles[index] = action
            saveToDisk()
            notifyObservers()
        }
    }
    
    // MARK: - Persistence Logic
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(quickActionBubbles)
            UserDefaults.standard.set(data, forKey: "saved_quick_actions")
        } catch {
            print("QuickActionsRepository: Failed to save data. Error: \(error)")
        }
    }
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "saved_quick_actions") {
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
