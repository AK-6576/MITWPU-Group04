//
//  Conversations.swift
//  ANSD_APP
//
//  Created by SDC-USER on 06/01/26.
//

import Foundation

// MARK: - Message Model

// Represents a single message in a conversation with sender information and metadata
struct Message: Codable, Identifiable, Sendable {
    var id: UUID
    var text: String
    let senderName: String
    let isIncoming: Bool
    var isHighlighted: Bool
    var senderId: String
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, text, senderName, isIncoming, isHighlighted, senderId, timestamp
    }
    
    // Standard initializer
    init(id: UUID = UUID(), text: String, senderId: String, senderName: String, isIncoming: Bool, timestamp: Date = Date(), isHighlighted: Bool = false) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.senderName = senderName
        self.isIncoming = isIncoming
        self.timestamp = timestamp
        self.isHighlighted = isHighlighted
    }
    
    // Robust decoder that handles missing optional fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        text = try container.decode(String.self, forKey: .text)
        senderName = try container.decode(String.self, forKey: .senderName)
        isIncoming = try container.decode(Bool.self, forKey: .isIncoming)
        isHighlighted = try container.decodeIfPresent(Bool.self, forKey: .isHighlighted) ?? false
        
        // Attempt to decode ID, otherwise generate new
        if let idString = try container.decodeIfPresent(String.self, forKey: .id),
           let uuid = UUID(uuidString: idString) {
            id = uuid
        } else {
            id = UUID()
        }
        
        // Attempt to decode SenderID, otherwise derive from logic
        senderId = try container.decodeIfPresent(String.self, forKey: .senderId) ?? (isIncoming ? "other" : "me")
        
        // Attempt to decode timestamp, otherwise use current time
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
    }
    
    // Default encoder is sufficient unless you need custom JSON transformation,
    // but explicit implementation ensures specific output format.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(senderName, forKey: .senderName)
        try container.encode(isIncoming, forKey: .isIncoming)
        try container.encode(isHighlighted, forKey: .isHighlighted)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// MARK: - Participant Model

struct PCParticipantData: Codable, Sendable {
    let name: String
    let summary: String
}

// MARK: - Conversation Model

struct Conversation: Codable, Identifiable, Sendable {
    let id: String
    var title: String
    var description: String
    var date: String
    var startTime: String
    var endTime: String
    var category: String
    var icon: String
    var info: Bool?
    var notes: String?
    var participants: [PCParticipantData]?
    var isPinned: Bool = false
    var messages: [Message]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, date, category, icon, info, notes, participants, messages
        case startTime = "start_time"
        case endTime = "end_time"
        case isPinned = "is_pinned"
    }
    
    init(id: String, title: String, messages: [Message] = [], participants: [PCParticipantData] = [], notes: String = "", description: String = "", date: String = "", startTime: String = "", endTime: String = "", category: String = "", icon: String = "") {
        self.id = id
        self.title = title
        self.messages = messages
        self.participants = participants
        self.notes = notes
        self.description = description
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.category = category
        self.icon = icon
    }
}

// MARK: - Response Container Models

struct PreviousMonth: Codable, Sendable {
    let month: String
    var conversations: [Conversation]
}

struct ConversationsResponse: Codable, Sendable {
    var conversations: [Conversation] = []
    var previousMonths: [PreviousMonth] = []

    enum CodingKeys: String, CodingKey {
        case conversations
        case previousMonths = "previous_months"
    }
}

// MARK: - Data Loader Service

// Dedicated service to handle data fetching, keeping models pure.
struct ConversationDataLoader {
    
    enum DataLoadError: Error {
        case fileNotFound
        case decodingFailed(Error)
    }
    
    /// Loads conversation data from the App Bundle
    static func load(from filename: String = "conversations") throws -> ConversationsResponse {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw DataLoadError.fileNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            // Optional: Add date formatting strategy if JSON dates are standard
            // decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ConversationsResponse.self, from: data)
        } catch {
            throw DataLoadError.decodingFailed(error)
        }
    }
}
