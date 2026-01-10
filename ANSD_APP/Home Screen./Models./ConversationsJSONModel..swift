//
//  ConversationJSONModels.swift
//  ANSD_APP
//

import Foundation

struct ConversationRoot: Codable {
    let conversations: [JSONConversation]
    let previous_months: [MonthSection]?
}

struct MonthSection: Codable {
    let month: String
    let conversations: [JSONConversation]
}

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

struct JSONParticipant: Codable {
    let name: String
    let summary: String
}

struct JSONMessage: Codable {
    let id: String
    let text: String
    let senderName: String
    let isIncoming: Bool
    let isHighlighted: Bool?
}
