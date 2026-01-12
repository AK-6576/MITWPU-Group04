//
//  QuickActionsData.swift
//  Group_4-ANSD_App
//

import Foundation

class QuickActionsRepository {
    
    static let shared = QuickActionsRepository()

    private var quickActionBubbles: [RoutineConversation] = []

    private var viewOnlyItems: [RoutineConversation] = []
    
    private init() {

        self.quickActionBubbles = [
            RoutineConversation(
                id: "1", iconName: "briefcase.fill", categoryTitle: "Office",
                status: "Upcoming", conversationTopic: "Scrum Meet", topicImage: "person.3.sequence.fill",
                startTime: "09:30 AM", description: "Updates on Project Stardust", date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "2", iconName: "figure.2.and.child.holdinghands", categoryTitle: "Family",
                status: "Scheduled", conversationTopic: "Brunch", topicImage: "fork.knife.circle.fill",
                startTime: "11:00 AM", description: "Weekly catch-up at The Toast Cafe.", date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "3_cafeteria", iconName: "person.3.fill", categoryTitle: "Friends",
                status: "Scheduled", conversationTopic: "Lunch", topicImage: "cup.and.saucer.fill",
                startTime: "12:30 PM", description: nil, date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_3", iconName: "figure.2.and.child.holdinghands", categoryTitle: "Family",
                status: "Scheduled", conversationTopic: "Date Night", topicImage: "film.stack.fill",
                startTime: "06:00 PM", description: "Discussed whether to see The Mandalorian movie.", date: "2025-10-05", timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_2", iconName: "person.3.fill", categoryTitle: "Friends",
                status: "Done", conversationTopic: "Cab Ride with Bucky Barnes", topicImage: "chart.bar.xaxis",
                startTime: "10:30 PM", description: "Discussed drop-off location, gate code, and cab fare.", date: "4 Oct 2025", timeImage: "clock.badge.checkmark.fill"
            )
        ]

        self.viewOnlyItems = [
            RoutineConversation(
                id: "conv_6", iconName: "figure.run", categoryTitle: "Friends",
                status: "Scheduled", conversationTopic: "Morning Jog", topicImage: "figure.run",
                startTime: "08:00 AM", description: "Running path discussion with neighbor.", date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "3", iconName: "person.3.fill", categoryTitle: "Friends",
                status: "Scheduled", conversationTopic: "Breakfast At VL", topicImage: "cup.and.saucer.fill",
                startTime: "08:00 AM", description: "Breakfast with Sarah and Mike.", date: "6 Oct 2025", timeImage: "clock"
            )
        ]
    }
    
    // MARK: - Data Access Methods
    func getGroupedSections() -> [RoutineSection] {
        let groupedDictionary = Dictionary(grouping: quickActionBubbles) { $0.categoryTitle }
        
        return groupedDictionary.map { (key, value) in
            let sortedItems = value.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
            return RoutineSection(category: key, items: sortedItems)
        }.sorted { $0.category < $1.category }
    }

    func getAllActions() -> [RoutineConversation] {
        let combined = quickActionBubbles + viewOnlyItems
        return combined.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
    }
    
    func addAction(_ action: RoutineConversation) {
        quickActionBubbles.append(action)
    }

    func deleteAction(_ action: RoutineConversation) {
        self.quickActionBubbles.removeAll { $0.id == action.id }
    }

    func updateAction(_ action: RoutineConversation) {
        if let index = self.quickActionBubbles.firstIndex(where: { $0.id == action.id }) {
            self.quickActionBubbles[index] = action
        }
    }
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
