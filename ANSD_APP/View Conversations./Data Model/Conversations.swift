//
//  Conversations.swift
//  ANSD_APP
//

import Foundation

// MARK: - 1. Message Struct (Updated for UI & JSON)
struct Message: Codable, Identifiable {
    var id: UUID = UUID() // Changed to UUID to fix HomeViewController mismatch
    var text: String
    let senderName: String
    let isIncoming: Bool
    var isHighlighted: Bool = false
    
    // Added these properties for the Chat UI
    var senderId: String = "other"
    var timestamp: Date = Date()
    
    // Custom CodingKeys to map JSON fields to our properties
    enum CodingKeys: String, CodingKey {
        case text, senderName, isIncoming, isHighlighted
        case id // JSON id is likely a String, we handle this in init(from:)
    }
    
    // Standard Init for HomeViewController
    init(id: UUID = UUID(), text: String, senderId: String, senderName: String, isIncoming: Bool, timestamp: Date = Date(), isHighlighted: Bool = false) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.senderName = senderName
        self.isIncoming = isIncoming
        self.timestamp = timestamp
        self.isHighlighted = isHighlighted
    }
    
    // Custom Decoder to handle JSON loading
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.senderName = try container.decode(String.self, forKey: .senderName)
        self.isIncoming = try container.decode(Bool.self, forKey: .isIncoming)
        self.isHighlighted = try container.decodeIfPresent(Bool.self, forKey: .isHighlighted) ?? false
        
        // Handle ID: If JSON has a string ID, we ignore it or hash it,
        // but for now we generate a new UUID to satisfy Identifiable
        self.id = UUID()
        
        // Calculate UI properties based on JSON data
        self.senderId = self.isIncoming ? "other" : "me"
        self.timestamp = Date() // Default to now for JSON loaded messages
    }
    
    func encode(to encoder: Encoder) throws {
        // Encoding logic if you ever need to save back to JSON
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(senderName, forKey: .senderName)
        try container.encode(isIncoming, forKey: .isIncoming)
        try container.encode(isHighlighted, forKey: .isHighlighted)
        try container.encode(id.uuidString, forKey: .id)
    }
}

// MARK: - 2. Participant Data Struct
struct PCParticipantData: Codable {
    let name: String
    let summary: String
}

// MARK: - 3. Conversation Struct (Updated for UI & JSON)
struct Conversation: Codable, Identifiable {
    let id: String
    var title: String
    var description: String // Made optional
    var date: String?        // Made optional
    var startTime: String   // Made optional
    var endTime: String     // Made optional
    var category: String    // Made optional
    var icon: String        // Made optional
    var info: Bool?
    var cal: Date?
    
    // Summary Data
    var notes: String?
    var participants: [PCParticipantData]?
    var isPinned: Bool = false
    var messages: [Message]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, date, category, icon, info, notes, participants
        case startTime = "start_time"
        case endTime = "end_time"
        case messages
    }
    
    // Manual Init for HomeViewController (The "UI" Initializer)
    init(id: String, title: String, messages: [Message] = [], participants: [PCParticipantData] = [], notes: String = "", description: String? = nil, date: String? = nil, startTime: String? = nil, endTime: String? = nil, category: String? = nil, icon: String? = nil) {
        self.id = id
        self.title = title
        self.messages = messages
        self.participants = participants
        self.notes = notes
        self.description = description!
        self.date = date!
        self.startTime = startTime!
        self.endTime = endTime!
        self.category = category!
        self.icon = icon!
    }
}

// MARK: - 4. Main Response & Loader
struct ConversationsResponse: Codable {
    var conversations: [Conversation] = []
    var previousMonths: [PreviousMonth] = []

    init() {
        if let response = try? load() {
            self.conversations = response.conversations
            self.previousMonths = response.previousMonths
        }
    }

    enum CodingKeys: String, CodingKey {
        case conversations
        case previousMonths = "previous_months"
    }
}

struct PreviousMonth: Codable {
    let month: String
    var conversations: [Conversation]
}

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
