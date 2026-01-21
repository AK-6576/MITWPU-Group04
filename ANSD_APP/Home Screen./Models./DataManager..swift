//
//  DataManager.swift
//  Group_4-ANSD_App
//

import Foundation

class DataManager {
    static let shared = DataManager()

    var conversations: [Conversation] = []
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        if let response = try? ConversationsResponse.load() {
            self.conversations = response.conversations
            print("DataManager: Successfully loaded \(self.conversations.count) conversations from JSON.")
        } else {
            print("DataManager: Failed to load conversations.json")
        }
    }

    func getConversation(byId id: String) -> Conversation? {
        return conversations.first { $0.id == id }
    }
}

// Data Model - SignUp screen.
struct FormField {
    let title: String
    var value: String
}
