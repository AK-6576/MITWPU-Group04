import Foundation

// MARK: - 1. Message Struct
struct Message: Codable {
    var text: String
    let senderName: String
    let isIncoming: Bool
    var isHighlighted: Bool = false
    let id: String
}

// MARK: - 2. Participant Data Struct (New)
struct PCParticipantData: Codable {
    let name: String
    let summary: String
}

// MARK: - Main Response
struct ConversationsResponse: Codable {
    var conversations: [Conversation] = []
    var previousMonths: [PreviousMonth] = []

    // Note: Creating an empty init that calls load() can be risky in multi-threaded environments,
    // but works for simple setups.
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

// MARK: - Conversation Struct
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
    var cal: Date?
    // Summary Data
    var notes: String?
    var participants: [PCParticipantData]? // Added to match JSON
    
    var isPinned: Bool = false
    var messages: [Message]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, date, category, icon, info, notes, participants
        case startTime = "start_time"
        case endTime = "end_time"
        case messages
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
