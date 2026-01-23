//
//  RoutineModels.swift
//  Group_4-ANSD_App
//  Created by Dhiraj Bodake on 15/01/26.

import Foundation

// MARK: - Data Models
struct QuickActionsConversation: Codable, Identifiable {
    let id: String
    let iconName: String
    let categoryTitle: String
    let status: String
    var conversationTopic: String
    let topicImage: String
    let startTime: String
    let description: String?
    let date: String?
    let timeImage: String
}

// MARK: - Section Model
struct RoutineSection {
    let category: String
    var items: [QuickActionsConversation]
}
