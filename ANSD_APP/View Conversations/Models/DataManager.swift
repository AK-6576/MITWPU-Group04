//
//  DataManager.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//
import Foundation
import SwiftData
import UIKit
import FirebaseAuth

class DataManager {
    static let shared = DataManager()

    // Safely retrieve the database context from the AppDelegate
    private var context: ModelContext? {
        return AppDelegate.dbContext
    }
    
    /// Returns the current authenticated user's UID, or empty string
    private var currentUID: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    private init() {}
    
    // 1. FETCH ALL: Gets all conversations for the current user
    func fetchConversations() -> [Conversation] {
        guard let context = context else { return [] }
        let uid = currentUID
        
        // Only fetch conversations belonging to the logged-in user
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate { $0.ownerUID == uid },
            sortBy: [SortDescriptor(\.calendarDate, order: .reverse)]
        )
        
        do {
            let fetchedData = try context.fetch(descriptor)
            print("DataManager: Successfully fetched \(fetchedData.count) conversations for UID \(uid).")
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
    
    // 3. ADD: Inserts a new conversation into the database (stamps ownerUID)
    func addConversation(_ conversation: Conversation) {
        guard let context = context else { return }
        
        // Tag the conversation with the current user's UID
        if conversation.ownerUID.isEmpty {
            conversation.ownerUID = currentUID
        }
        
        context.insert(conversation)
        saveData()
        
        // Push the metadata to the user's Firebase history
        FirebaseManager.shared.saveConversationMetadata(conversation)
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
            // Trigger UI refresh for conversation-related views (Home Screen, View Conversations, etc.)
            NotificationCenter.default.post(name: NSNotification.Name("ConversationHistoryUpdated"), object: nil)
        } catch {
            print("DataManager: Failed to save context. Error: \(error.localizedDescription)")
        }
    }
    
    // 6. FETCH BY DATE: Fetches conversations for a specific day (scoped by UID)
    func fetchConversations(for date: Date) -> [Conversation] {
        guard let context = context else { return [] }
        let uid = currentUID

        // Define the start and end of the selected day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        let fallbackDate = Date.distantPast

        // Fetch using a Predicate to filter at the database level, scoped by UID
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate {
                $0.ownerUID == uid &&
                ($0.calendarDate ?? fallbackDate) >= startOfDay &&
                ($0.calendarDate ?? fallbackDate) < endOfDay
            },
            sortBy: [SortDescriptor(\.calendarDate, order: .reverse)]
        )

        do {
            let fetchedData = try context.fetch(descriptor)
            print("DataManager: 📅 Successfully fetched \(fetchedData.count) conversations for date: \(date)")
            return fetchedData
        } catch {
            print("DataManager: ❌ Failed to fetch filtered data. Error: \(error.localizedDescription)")
            return []
        }
    }
    
    // 7. CLEAR ALL: Wipes all local SwiftData to prevent data leakage on logout
    func clearAllLocalData() {
        guard let context = context else { return }
        do {
            try context.delete(model: Conversation.self)
            try context.delete(model: Message.self)
            try context.delete(model: Participant.self)
            try context.delete(model: VoiceProfile.self)
            try context.save()
            print("DataManager: Successfully wiped all local SwiftData.")
            NotificationCenter.default.post(name: NSNotification.Name("ConversationHistoryUpdated"), object: nil)
        } catch {
            print("DataManager: Failed to wipe SwiftData. Error: \(error.localizedDescription)")
        }
    }
}
