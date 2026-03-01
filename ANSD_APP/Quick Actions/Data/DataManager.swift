//
//  DataManager.swift
//  Group_4-ANSD_App
//

import Foundation

class DataManager {
    static let shared = DataManager()

    var conversations: [Conversation] = []
    
    // 1. Create a path to the device's local Documents directory
    private var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("saved_conversations.json")
    }
    
    private init() {
        loadData()
    }
    
    // 2. Upgraded to read from the device, not the read-only app bundle
    private func loadData() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            self.conversations = try decoder.decode([Conversation].self, from: data)
            print("DataManager: Successfully loaded \(self.conversations.count) conversations from Documents.")
        } catch {
            // If it fails (like on the very first app launch), it just starts empty.
            print("DataManager: No saved data found. Starting fresh.")
            self.conversations = []
        }
    }
    
    // 3. NEW: A function to physically save the array to the device
    func saveData() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self.conversations)
            try data.write(to: fileURL)
            print("DataManager: Successfully saved \(self.conversations.count) conversations.")
        } catch {
            print("DataManager: Failed to save data. Error: \(error)")
        }
    }
    
    // 4. NEW: A function for your Summary Screens to call to add a new session
    func addConversation(_ conversation: Conversation) {
        // Insert at the beginning so the newest session appears at the top of the history list
        conversations.insert(conversation, at: 0)
        saveData()
    }

    // Retained your original fetch method
    func getConversation(byId id: String) -> Conversation? {
        return conversations.first { $0.id == id }
    }
}
