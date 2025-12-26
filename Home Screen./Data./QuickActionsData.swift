//
//  HomeDataModels.swift
//  ANSD_APP
//
//  Created by Daiwiik on 16/12/25.
//

import Foundation

// 2. The Repository with the integrated data
class QuickActionsRepository {
    
    static func getAllActions() -> [RoutineConversation] {
        return [
            // --- SECTION 1: QUICK ACTIONS (First 4 items usually) ---
            
            RoutineConversation(
                id: "1",
                iconName: "captions.bubble.fill",
                categoryTitle: "Office",
                status: "Upcoming",
                conversationTopic: "Scrum Meet",
                topicImage: "text.bubble",
                timeRange: "09:30 - 10:00 AM",
                description: "Updates on Project Stardust",
                date: nil,
                timeImage: "clock"
            ),
            RoutineConversation(
                id: "2",
                iconName: "figure.2.and.child.holdinghands",
                categoryTitle: "Family",
                status: "Scheduled",
                conversationTopic: "Brunch with Amanda",
                topicImage: "fork.knife",
                timeRange: "10:00 - 12:00 PM",
                description: nil,
                date: nil,
                timeImage: "clock"
            ),
            RoutineConversation(
                id: "3",
                iconName: "person.3.fill",
                categoryTitle: "Friends",
                status: "Scheduled",
                conversationTopic: "Cafeteria Hangout",
                topicImage: "cup.and.saucer.fill",
                timeRange: "12:30 - 01:30 PM",
                description: nil,
                date: nil,
                timeImage: "clock"
            ),
            
            RoutineConversation(
                id: "conv_2",
                iconName: "person.3.fill",
                categoryTitle: "Friends",
                status: "Completed",
                conversationTopic: "Marvel Theories & Spoilers",
                topicImage: "film.fill",
                timeRange: "10:30 PM - 11:30 PM",
                description: "Discussed Avengers Doomsday, the new cast, and potential plot consequences.",
                date: "2025-10-04",
                timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_3",
                iconName: "figure.2.and.child.holdinghands",
                categoryTitle: "Family",
                status: "Scheduled",
                conversationTopic: "Movie Watch",
                topicImage: "popcorn.fill",
                timeRange: "09:30 AM - 10:30 AM",
                description: "Discussed whether to see The Mandalorian movie.",
                date: "2025-10-05",
                timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_5",
                iconName: "briefcase.fill",
                categoryTitle: "Office",
                status: "In Progress",
                conversationTopic: "Project Alpha Status",
                topicImage: "chart.bar.doc.horizontal",
                timeRange: "03:00 PM - 03:15 PM",
                description: "Quick sync-up on the Project Alpha deliverable timeline.",
                date: "2025-10-06",
                timeImage: "clock"
            )
        ]
    }
}
