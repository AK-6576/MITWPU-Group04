//
//  RoutineModels.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation

// MARK: - Routine Data Models
// Defines the structures for routine conversations and their categorization into sections.
struct RoutineConversation: Codable, Identifiable {
    let id: String
    let iconName: String
    let categoryTitle: String
    let status: String
    var conversationTopic: String
    let topicImage: String
    var startTime: String
    let description: String?
    let date: String?
    let timeImage: String
    var roomCode: String?
    var participantNames: [String]
}

// MARK: - Section Model
struct RoutineSection {
    let category: String
    var items: [RoutineConversation]
}
