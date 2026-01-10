//
//  DataManager.swift
//  Group_4-ANSD_App
//

import Foundation

class DataManager {
    // Singleton instance: Access this via 'DataManager.shared'
    static let shared = DataManager()
    
    // The loaded data
    var conversations: [Conversation] = []
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        // Attempt to load conversations.json using the struct from Conversations.swift
        if let response = try? ConversationsResponse.load() {
            self.conversations = response.conversations
            print("DataManager: Successfully loaded \(self.conversations.count) conversations from JSON.")
        } else {
            print("DataManager: Failed to load conversations.json")
        }
    }
    
    // Helper to find a specific conversation
    func getConversation(byId id: String) -> Conversation? {
        return conversations.first { $0.id == id }
    }
}
