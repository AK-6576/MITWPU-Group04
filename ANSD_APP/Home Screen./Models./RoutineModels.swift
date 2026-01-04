//
//  RoutineModels.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 10/12/25.
//

import Foundation

struct RoutineResponse: Codable {
    let routine_conversations: [RoutineConversation]
    let view_conversations: [RoutineConversation]
}

struct RoutineConversation: Codable, Identifiable {
    let id: String
    let iconName: String
    let categoryTitle: String
    let status: String
    var conversationTopic: String
    let topicImage: String
    let timeRange: String
    let description: String?
    let date: String?
    let timeImage: String
}
