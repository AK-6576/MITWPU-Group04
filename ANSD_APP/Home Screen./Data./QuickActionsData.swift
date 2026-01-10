//
//  QuickActionsData.swift
//  Group_4-ANSD_App
//

import Foundation

class QuickActionsRepository {
    
    static let shared = QuickActionsRepository()
    
    private var allActions: [RoutineConversation] = []
    
    private init() {
        self.allActions = [
            RoutineConversation(
                id: "1", iconName: "briefcase.fill", categoryTitle: "Office",
                status: "Upcoming", conversationTopic: "Scrum Meet", topicImage: "person.3.sequence.fill",
                startTime: "09:30 AM", description: "Updates on Project Stardust", date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "2", iconName: "figure.2.and.child.holdinghands", categoryTitle: "Family",
                status: "Scheduled", conversationTopic: "Brunch with Amanda", topicImage: "fork.knife.circle.fill",
                startTime: "11:00 AM", description: nil, date: nil, timeImage: "clock"
            ),
            RoutineConversation(
                id: "3", iconName: "person.3.fill", categoryTitle: "Friends",
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
    }
    
    func addAction(_ action: RoutineConversation) {
        allActions.append(action)
    }
    
    // MARK: - Home Screen Data (Sorted by Time)
    func getAllActions() -> [RoutineConversation] {
        return allActions.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
    }
    
    // MARK: - Quick Actions Screen Data (Grouped & Sorted)
    func getGroupedSections() -> [RoutineSection] {
        let groupedDictionary = Dictionary(grouping: allActions) { $0.categoryTitle }
        
        return groupedDictionary.map { (key, value) in
            let sortedItems = value.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
            return RoutineSection(category: key, items: sortedItems)
        }.sorted { $0.category < $1.category }
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
