class QuickActionsRepository {
    
    static func getAllActions() -> [RoutineConversation] {
        return [
            RoutineConversation(
                id: "1",
                iconName: "captions.bubble.fill",          // Office – Scrum Meet [web:20]
                categoryTitle: "Office",
                status: "Upcoming",
                conversationTopic: "Scrum Meet",
                topicImage: "person.3.sequence.fill",      // Standup / scrum [web:24]
                startTime: "09:30 AM",
                description: "Updates on Project Stardust",
                date: nil,
                timeImage: "clock"
            ),
            RoutineConversation(
                id: "2",
                iconName: "figure.2.and.child.holdinghands", // Family – Brunch
                categoryTitle: "Family",
                status: "Scheduled",
                conversationTopic: "Brunch with Amanda",
                topicImage: "fork.knife.circle.fill",      // Food / brunch [web:20]
                startTime: "10:00 PM",
                description: nil,
                date: nil,
                timeImage: "clock"
            ),
            RoutineConversation(
                id: "3",
                iconName: "person.3.fill",                 // Friends – Hangout
                categoryTitle: "Friends",
                status: "Scheduled",
                conversationTopic: "Cafeteria Hangout",
                topicImage: "cup.and.saucer.fill",         // Coffee / café
                startTime: "12:30 PM",
                description: nil,
                date: nil,
                timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_3",
                iconName: "person.2.crop.square.stack.fill", // Family – Movie night (different from id:2) [web:28]
                categoryTitle: "Family",
                status: "Scheduled",
                conversationTopic: "Movie Watch",
                topicImage: "film.stack.fill",             // Movie / cinema
                startTime: "09:30 AM",
                description: "Discussed whether to see The Mandalorian movie.",
                date: "2025-10-05",
                timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_5",
                iconName: "briefcase.fill",                // Office – Project status
                categoryTitle: "Office",
                status: "In Progress",
                conversationTopic: "Project Alpha Status",
                topicImage: "chart.bar.xaxis",             // Status / progress
                startTime: "03:00 PM",
                description: "Quick sync-up on the Project Alpha deliverable timeline.",
                date: "2025-10-06",
                timeImage: "clock.badge.checkmark.fill"    // Done / in progress [web:25]
            )
        ]
    }
}
