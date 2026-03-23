//
//  QuickCaptionsChat.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation

struct QuickCaptionsChat: Sendable {
    var sender: String
    var senderID: String
    var text: String
    var isIncoming: Bool
    var speakerID: Int?
    var eventId: UUID?
}
