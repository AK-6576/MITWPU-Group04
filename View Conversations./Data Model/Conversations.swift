//
//  Conversations.swift
//  Group_4-ANSD_App
//
//  Created by Omkar Varpe on 26/11/25.
//

import Foundation

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
    var title: String        // Changed to var
    var description: String  // Changed to var
    var date: String
    var startTime: String
    var endTime: String
    var category: String
    var icon: String
    var info: Bool?
    
    // NEW: For pinning functionality (defaults to false if not in JSON)
    var isPinned: Bool = false

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case startTime = "start_time"
        case endTime = "end_time"
        case category
        case icon
        case info
    }
}

// MARK: - Previous Month
struct PreviousMonth: Codable {
    let month: String
    var conversations: [Conversation] // Changed to var
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
