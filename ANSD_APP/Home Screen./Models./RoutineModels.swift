//
//  RoutineModels.swift
//  ANSD_APP
//

import Foundation

// MARK: - Data Models
struct RoutineConversation: Codable, Identifiable {
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
    // 'var' allows us to delete/move items within the section
    var items: [RoutineConversation]
}
