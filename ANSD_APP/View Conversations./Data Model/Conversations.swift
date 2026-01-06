//
//  Conversations.swift
//  Group_4-ANSD_App
//
//  Created by Omkar Varpe on 26/11/25.
//

import Foundation

// MARK: - 1. Add the Message Data Structure (Required for chat history)
// This structure must match what your UICollectionView cells are expecting.
struct Message: Codable {
    let text: String
    let senderName: String
    let isIncoming: Bool // true = Incoming (Gray), false = Outgoing (Blue)
    
    // An ID is useful for tracking messages, especially if they are retrieved from a database/API
    let id: String
    
    // If your source data (like PCChatData) uses different key names,
    // you might need a CodingKeys enum here for JSON decoding.
}

// MARK: - Main Response
struct ConversationsResponse: Codable {

    var conversations: [Conversation] = []
    var previousMonths: [PreviousMonth] = []

    init() {
        do {
            let response = try load()
            conversations = response.conversations
            previousMonths = response.previousMonths
        } catch {
            print(error.localizedDescription)
        }
    }

    enum CodingKeys: String, CodingKey {
        case conversations
        case previousMonths = "previous_months"
    }
}

// MARK: - Conversation
struct Conversation: Codable, Identifiable {
    let id: String
    var title: String
    var description: String
    var date: String
    var startTime: String
    var endTime: String
    var category: String
    var icon: String
    var info: Bool?
    
    // NEW: For pinning functionality (defaults to false if not in JSON)
    var isPinned: Bool = false

    // MARK: - 2. Add the messages property
    // This holds the actual chat transcript. It is optional (?) because not all
    // conversation entries (like those in previousMonths) might need to load the full chat history immediately.
    var messages: [Message]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case category
        case icon
        case info
        
        // Match JSON keys
        case startTime = "start_time"
        case endTime = "end_time"
        case messages // Ensure your conversation JSON includes this key for the chat transcript
    }
}

// MARK: - Previous Month
struct PreviousMonth: Codable {
    let month: String
    var conversations: [Conversation]
}

// MARK: - Loader
extension ConversationsResponse {
    func load(from filename: String = "conversations") throws -> ConversationsResponse {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw NSError(domain: "ConversationsResponse", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "conversations.json not found"])
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(ConversationsResponse.self, from: data)
    }
}
