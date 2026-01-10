//
//  QuickActionsData.swift
//  Group_4-ANSD_App
//

import Foundation

class QuickActionsRepository {
    
    static let shared = QuickActionsRepository()
    
    // LIST 1: The Standard Items
    // These will appear in the bottom "Quick Actions" list on Home (because they are later in the day)
    private var quickActionBubbles: [RoutineConversation] = []
    
    // LIST 2: The Early Items
    // These are set for 6 AM and 8 AM. Because they are earliest,
    // they will be the top 2 items in "View Conversations" on Home.
    private var viewOnlyItems: [RoutineConversation] = []
    
    private init() {
        // ---------------------------------------------------------
        // 1. POPULATE STANDARD ITEMS (Later in the day)
        // ---------------------------------------------------------
        self.quickActionBubbles = [
            RoutineConversation(
                id: "1", iconName: "briefcase.fill", categoryTitle: "Office",
                status: "Upcoming", conversationTopic: "Scrum Meet", topicImage: "person.3.sequence.fill",
                startTime: "09:30 AM", description: "Updates on Project Stardust", date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "2", iconName: "figure.2.and.child.holdinghands", categoryTitle: "Family",
                status: "Scheduled", conversationTopic: "Brunch with Amanda", topicImage: "fork.knife.circle.fill",
                startTime: "11:00 AM", description: "Weekly catch-up at The Toast Cafe.", date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "3_cafeteria", iconName: "person.3.fill", categoryTitle: "Friends",
                status: "Scheduled", conversationTopic: "Cafeteria Hangout", topicImage: "cup.and.saucer.fill",
                startTime: "12:30 PM", description: nil, date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_3", iconName: "figure.2.and.child.holdinghands", categoryTitle: "Family",
                status: "Scheduled", conversationTopic: "Movie Watch", topicImage: "film.stack.fill",
                startTime: "06:00 PM", description: "Discussed whether to see The Mandalorian movie.", date: "2025-10-05", timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_2", iconName: "person.3.fill", categoryTitle: "Friends",
                status: "Done", conversationTopic: "Cab Ride with Bucky Barnes", topicImage: "chart.bar.xaxis",
                startTime: "10:30 PM", description: "Discussed drop-off location, gate code, and cab fare.", date: "4 Oct 2025", timeImage: "clock.badge.checkmark.fill"
            )
        ]
        
        // ---------------------------------------------------------
        // 2. POPULATE EARLY ITEMS (Morning)
        // ---------------------------------------------------------
        self.viewOnlyItems = [
            RoutineConversation(
                id: "conv_6", iconName: "figure.run", categoryTitle: "Friends",
                status: "Scheduled", conversationTopic: "Morning Jog", topicImage: "figure.run",
                startTime: "07:00 AM", description: "Running path discussion with neighbor.", date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "3", iconName: "person.3.fill", categoryTitle: "Friends",
                status: "Scheduled", conversationTopic: "Breakfast At VL", topicImage: "cup.and.saucer.fill",
                startTime: "06:00 AM", description: "Breakfast with Sarah and Mike.", date: nil, timeImage: "clock"
            )
        ]
    }
    
    // MARK: - Data Access Methods
    
    // Used by the Quick Actions Tab (The Bubbles Screen)
    func getGroupedSections() -> [RoutineSection] {
        let groupedDictionary = Dictionary(grouping: quickActionBubbles) { $0.categoryTitle }
        
        return groupedDictionary.map { (key, value) in
            let sortedItems = value.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
            return RoutineSection(category: key, items: sortedItems)
        }.sorted { $0.category < $1.category }
    }
    
    // Used by HomeViewController
    // Combines EVERYTHING and sorts by time.
    // Result: Jog (6am) -> Breakfast (8am) -> Scrum (9:30am) -> etc.
    func getAllActions() -> [RoutineConversation] {
        let combined = quickActionBubbles + viewOnlyItems
        return combined.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
    }
    
    func addAction(_ action: RoutineConversation) {
        // Add new actions to the main list
        quickActionBubbles.append(action)
    }
    
    // Helper to sort "06:00 AM" before "09:30 AM"
    private func compareTimes(time1: String, time2: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let d1 = formatter.date(from: time1),
              let d2 = formatter.date(from: time2) else {
            return false
        }
        return d1 < d2
    }
}
