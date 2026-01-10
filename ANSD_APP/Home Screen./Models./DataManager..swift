//
//  DataManager.swift
//  ANSD_APP
//

import Foundation

class DataManager {
    static let shared = DataManager()
    
    // This holds all conversations loaded from the file
    var allConversations: [JSONConversation] = []
    
    private init() {
        loadData()
    }
    
    func loadData() {
        // Ensure you have a file named 'conversations.json' in your Xcode project
        guard let url = Bundle.main.url(forResource: "conversations", withExtension: "json") else {
            print("Error: conversations.json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decodedData = try JSONDecoder().decode(ConversationRoot.self, from: data)
            
            // Flatten the list: Add top-level conversations
            allConversations.append(contentsOf: decodedData.conversations)
            
            // Add previous months conversations if they exist
            if let pastMonths = decodedData.previous_months {
                for month in pastMonths {
                    allConversations.append(contentsOf: month.conversations)
                }
            }
            print("Successfully loaded \(allConversations.count) conversations from JSON.")
            
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }
    
    // Helper to find a specific conversation by ID
    func getConversation(byId id: String) -> JSONConversation? {
        return allConversations.first { $0.id == id }
    }
}
