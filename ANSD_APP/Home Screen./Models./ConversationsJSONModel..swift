//
//  ConversationJSONModels.swift
//  ANSD_APP
//

import Foundation

// 1. The Root structure of your JSON
struct ConversationRoot: Codable {
    let conversations: [JSONConversation]
    let previous_months: [MonthSection]?
}

// 2. Handling the "Previous Months" section
struct MonthSection: Codable {
    let month: String
    let conversations: [JSONConversation]
}

// 3. The actual Conversation Data (Raw JSON)
struct JSONConversation: Codable {
    let id: String
    let title: String
    let description: String?
    let notes: String?
    let participants: [JSONParticipant]
    let date: String
    let start_time: String
    let end_time: String
    let category: String
    let messages: [JSONMessage]
}

// 4. Participants (Raw JSON)
struct JSONParticipant: Codable {
    let name: String
    let summary: String
}

// 5. Messages (Raw JSON)
struct JSONMessage: Codable {
    let id: String
    let text: String
    let senderName: String
    let isIncoming: Bool
    let isHighlighted: Bool?
}
