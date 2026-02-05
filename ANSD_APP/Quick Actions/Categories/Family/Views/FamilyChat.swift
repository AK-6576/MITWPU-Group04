//
//  FamilyChat.swift
//  ANSD_APP
//
//  Created by SDC-USER on 05/02/26.
//

import Foundation

// 1. This defines the categories so the errors in Summary and Routine disappear
enum ChatCategory {
    case family
    case friends
    case work
}

// 2. This defines what a message looks like
struct ChatMessage {
    let text: String
    let isIncoming: Bool
    let sender: String
}

// 3. This defines the rules for a message (used by your Join controllers)
protocol ChatMessageProtocol {
    var text: String { get }
    var sender: String { get }
    var isIncoming: Bool { get }
}

extension ChatMessage: ChatMessageProtocol {}
