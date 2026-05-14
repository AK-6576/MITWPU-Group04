//
//  ConversationDataModels.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - Participant Model
@Model
class Participant {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var summary: String
    var image: String

    var conversation: Conversation?

    init(name: String, summary: String, image: String) {
        self.name = name
        self.summary = summary
        self.image = image
    }
}

// MARK: - Message Model
@Model
class Message {
    @Attribute(.unique) var id: UUID
    var text: String
    var senderName: String
    var isIncoming: Bool
    var isHighlighted: Bool
    var senderId: String
    var timestamp: Date
    var isEdited: Bool

    var conversation: Conversation?

    init(id: UUID = UUID(), text: String, senderId: String, senderName: String, isIncoming: Bool, timestamp: Date = Date(), isHighlighted: Bool = false, isEdited: Bool = false) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.senderName = senderName
        self.isIncoming = isIncoming
        self.timestamp = timestamp
        self.isHighlighted = isHighlighted
        self.isEdited = isEdited
    }
}

// MARK: - Conversation Model
@Model
class Conversation {
    @Attribute(.unique) var id: String
    var title: String
    var details: String
    var date: String
    var startTime: String
    var endTime: String
    var category: String
    var icon: String
    var location: String = ""
    var info: Bool?
    var calendarDate: Date?
    var notes: String?
    var isPinned: Bool
    var ownerUID: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Participant.conversation) var participants: [Participant]?
    @Relationship(deleteRule: .cascade, inverse: \Message.conversation) var messages: [Message]?

    init(id: String, title: String, details: String = "", date: String = "", startTime: String = "", endTime: String = "", location: String = "", category: String = "", icon: String = "", info: Bool? = nil, calendarDate: Date? = nil, notes: String? = nil, isPinned: Bool = false, ownerUID: String = "", participants: [Participant]? = [], messages: [Message]? = []) {
        self.id = id
        self.title = title
        self.details = details
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.category = category
        self.icon = icon
        self.info = info
        self.calendarDate = calendarDate
        self.notes = notes
        self.isPinned = isPinned
        self.ownerUID = ownerUID
        self.participants = participants
        self.messages = messages
    }
}
