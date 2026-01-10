//
//  QuickActionsData.swift
//  Group_4-ANSD_App
//

import Foundation

class QuickActionsRepository {
    
    // 1. Raw Data Source
    static func getAllActions() -> [RoutineConversation] {
        return [
            RoutineConversation(
                id: "1", iconName: "captions.bubble.fill", categoryTitle: "Office",
                status: "Upcoming", conversationTopic: "Scrum Meet", topicImage: "person.3.sequence.fill",
                startTime: "09:30 AM", description: "Updates on Project Stardust", date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "2", iconName: "figure.2.and.child.holdinghands", categoryTitle: "Family",
                status: "Scheduled", conversationTopic: "Brunch with Amanda", topicImage: "fork.knife.circle.fill",
                startTime: "10:00 PM", description: nil, date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "3", iconName: "person.3.fill", categoryTitle: "Friends",
                status: "Scheduled", conversationTopic: "Cafeteria Hangout", topicImage: "cup.and.saucer.fill",
                startTime: "12:30 PM", description: nil, date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_3", iconName: "person.2.crop.square.stack.fill", categoryTitle: "Family",
                status: "Scheduled", conversationTopic: "Movie Watch", topicImage: "film.stack.fill",
                startTime: "09:30 AM", description: "Discussed whether to see The Mandalorian movie.", date: "2025-10-05", timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_5", iconName: "person.3.fill", categoryTitle: "Friends",
                status: "In Progress", conversationTopic: "Cab Ride with Bucky Barnes", topicImage: "chart.bar.xaxis",
                startTime: "10:30 PM", description: "Discussed drop-off location, gate code, and cab fare.", date: "4 Oct 2025", timeImage: "clock.badge.checkmark.fill"
            ),
            RoutineConversation(
                id: "conv_6", iconName: "figure.2.and.child.holdinghands.fill", categoryTitle: "Family",
                status: "In Progress", conversationTopic: "Movie Watch", topicImage: "chart.bar.xaxis",
                startTime: "9:30 AM", description: "Discussed whether to see The Mandalorian movie.", date: "4 Oct 2025", timeImage: "clock.badge.checkmark.fill"
            )
        ]
    }
    
    // 2. Grouping Logic
    static func getGroupedSections() -> [RoutineSection] {
        let allItems = getAllActions()
        let groupedDictionary = Dictionary(grouping: allItems) { $0.categoryTitle }
        
        return groupedDictionary.map { (key, value) in
            RoutineSection(category: key, items: value)
        }.sorted { $0.category < $1.category }
    }
}
