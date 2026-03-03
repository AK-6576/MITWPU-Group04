//
//  ActionSessions.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation

struct SessionModel {
    var title: String
    let subtitle: String
    let category: ChatCategory // Links the session to Family, Friends, or Work
    let date: Date
}
