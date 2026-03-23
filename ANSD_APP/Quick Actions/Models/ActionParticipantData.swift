//
//  ActionParticipantData.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation

// 1. This is the "Identity Card" for a person.
struct ParticipantData {
    var name: String
    var senderID: String
    var summary: String
    var isCurrentUser: Bool = false
}

