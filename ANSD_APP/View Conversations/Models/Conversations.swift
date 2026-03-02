////
////  Conversations.swift
////  ANSD_APP
////
////  Created by SDC-USER on 06/01/26.
////
//
//import Foundation
//
//// MARK: - Message Model
//
//struct Message: Codable, Identifiable, Sendable {
//    var id: UUID = UUID()
//    var text: String
//    let senderName: String
//    let isIncoming: Bool
//    var isHighlighted: Bool = false
//    var senderId: String = "other"
//    var timestamp: Date = Date()
//    var isEdited: Bool = false
//    
//    enum CodingKeys: String, CodingKey {
//        case text, senderName, isIncoming, isHighlighted, id , isEdited
//    }
//    
//    init(id: UUID = UUID(), text: String, senderId: String, senderName: String, isIncoming: Bool, timestamp: Date = Date(), isHighlighted: Bool = false,isEdited: Bool = false) {
//        self.id = id
//        self.text = text
//        self.senderId = senderId
//        self.senderName = senderName
//        self.isIncoming = isIncoming
//        self.timestamp = timestamp
//        self.isHighlighted = isHighlighted
//        self.isEdited = isEdited
//    }
//    
//    // Encoder - Decoder.
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        text = try container.decode(String.self, forKey: .text)
//        senderName = try container.decode(String.self, forKey: .senderName)
//        isIncoming = try container.decode(Bool.self, forKey: .isIncoming)
//        isHighlighted = try container.decodeIfPresent(Bool.self, forKey: .isHighlighted) ?? false
//        isEdited = try container.decodeIfPresent(Bool.self, forKey: .isEdited) ?? false
//        
//        id = UUID()
//        senderId = isIncoming ? "other" : "me"
//        timestamp = Date()
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(text, forKey: .text)
//        try container.encode(senderName, forKey: .senderName)
//        try container.encode(isIncoming, forKey: .isIncoming)
//        try container.encode(isHighlighted, forKey: .isHighlighted)
//        try container.encode(id.uuidString, forKey: .id)
//        try container.encode(isEdited, forKey: .isEdited)
//    }
//}
//
//// MARK: - Participant Model
//
//struct Participant: Codable, Sendable {
//    var name: String
//    var summary: String
//    var image: String
//}
//
//// MARK: - Conversation Model
//struct Conversation: Codable, Identifiable, Sendable {
//    let id: String
//    var title: String
//    var description: String
//    var date: String
//    var startTime: String
//    var endTime: String
//    var category: String
//    var icon: String
//    var info: Bool?
//    var calendarDate: Date?
//    var notes: String?
//    var participants: [Participant]?
//    var isPinned: Bool = false
//    var messages: [Message]?
//
//    enum CodingKeys: String, CodingKey {
//        case id, title, description, date, category, icon, info, notes, participants, messages
//        case startTime = "start_time"
//        case endTime = "end_time"
//    }
//
//    init(id: String, title: String, messages: [Message] = [], participants: [Participant] = [], notes: String = "", description: String = "", date: String = "", startTime: String = "", endTime: String = "", category: String = "", icon: String = "") {
//        self.id = id
//        self.title = title
//        self.messages = messages
//        self.participants = participants
//        self.notes = notes
//        self.description = description
//        self.date = date
//        self.startTime = startTime
//        self.endTime = endTime
//        self.category = category
//        self.icon = icon
//    }
//}
//
//// MARK: - Response Container Models
//
//struct PreviousMonth: Codable, Sendable {
//    let month: String
//    var conversations: [Conversation]
//}
//
//struct ConversationsResponse: Codable, Sendable {
//    var conversations: [Conversation] = []
//    var previousMonths: [PreviousMonth] = []
//
//    enum CodingKeys: String, CodingKey {
//        case conversations
//        case previousMonths = "previous_months"
//    }
//    
//    init() {
//        if let response = try? Self.load() {
//            self.conversations = response.conversations
//            self.previousMonths = response.previousMonths
//        }
//    }
//
//    static func load(from filename: String = "conversations") throws -> ConversationsResponse {
//        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
//            throw NSError(domain: "ConversationsResponse", code: 404,
//                          userInfo: [NSLocalizedDescriptionKey: "conversations.json not found"])
//        }
//
//        let data = try Data(contentsOf: url)
//        let decoder = JSONDecoder()
//        return try decoder.decode(ConversationsResponse.self, from: data)
//    }
//}
