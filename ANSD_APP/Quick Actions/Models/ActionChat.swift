//
//  ActionChat.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 05/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation

// 1. This defines the categories so the errors in Summary and Routine disappear
enum ChatCategory: String, CaseIterable {
    case family = "Family"
    case friends = "Friends"
    case office = "Office"
    case other = "Other"
}

// 2. This defines what a message looks like
struct ChatMessage {
    let text: String
    let isIncoming: Bool
    let sender: String
    let senderID: String
}

// 3. This defines the rules for a message (used by your Join controllers)
protocol ChatMessageProtocol {
    var text: String { get }
    var sender: String { get }
    var isIncoming: Bool { get }
}



extension ChatMessage: ChatMessageProtocol {}
