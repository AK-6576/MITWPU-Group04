//
//  DataManager.swift
//  Group_4-ANSD_App
//

import Foundation
import SwiftData
import UIKit

class DataManager {
    static let shared = DataManager()

    // Safely retrieve the database context from the AppDelegate
    private var context: ModelContext? {
        return AppDelegate.dbContext
    }
    
    private init() {}
    
    // 1. FETCH ALL: Gets all conversations for your list views
    func fetchConversations() -> [Conversation] {
        guard let context = context else { return [] }
        
        // Sorts descending so the newest chats appear at the top
        let descriptor = FetchDescriptor<Conversation>(sortBy: [SortDescriptor(\.calendarDate, order: .reverse)])
        
        do {
            let fetchedData = try context.fetch(descriptor)
            print("DataManager: Successfully fetched \(fetchedData.count) conversations.")
            return fetchedData
        } catch {
            print("DataManager: Failed to fetch data. Error: \(error.localizedDescription)")
            return []
        }
    }
    
    // 2. FETCH BY ID: Finds a single specific conversation (used by HomeViewController)
    func fetchConversation(byId id: String) -> Conversation? {
        guard let context = context else { return nil }
        
        let descriptor = FetchDescriptor<Conversation>(predicate: #Predicate { $0.id == id })
        
        do {
            let results = try context.fetch(descriptor)
            return results.first
        } catch {
            print("DataManager: Failed to fetch conversation by ID. Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 3. ADD: Inserts a new conversation into the database
    func addConversation(_ conversation: Conversation) {
        guard let context = context else { return }
        context.insert(conversation)
        saveData()
    }
    
    // 4. DELETE: Removes a conversation from the database
    func deleteConversation(_ conversation: Conversation) {
        guard let context = context else { return }
        context.delete(conversation)
        saveData()
    }
    
    // 5. SAVE: Commits any edits made to existing objects
    func saveData() {
        guard let context = context else { return }
        do {
            try context.save()
            print("DataManager: Successfully saved changes.")
        } catch {
            print("DataManager: Failed to save context. Error: \(error.localizedDescription)")
        }
    }
}
