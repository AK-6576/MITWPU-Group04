//
//  QuickActionsData.swift
//  Group_4-ANSD_App
//

import Foundation

class QuickActionsRepository {
    
    // MARK: - 1. Singleton Instance
    // This allows all screens to access the exact same list of data.
    static let shared = QuickActionsRepository()
    
    // Private master list
    private var allActions: [RoutineConversation] = []
    
    // Private init so no one else can create a new instance
    private init() {
        loadDummyData()
    }
    
    private func loadDummyData() {
        self.allActions = [
            RoutineConversation(
                id: "1", iconName: "captions.bubble.fill", categoryTitle: "Office",
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
                id: "conv_3", iconName: "person.2.crop.square.stack.fill", categoryTitle: "Family",
                status: "Scheduled", conversationTopic: "Movie Watch", topicImage: "film.stack.fill",
                startTime: "06:00 PM", description: "Discussed whether to see The Mandalorian movie.", date: "2025-10-05", timeImage: "clock"
            ),
            RoutineConversation(
                id: "conv_5", iconName: "person.3.fill", categoryTitle: "Friends",
                status: "In Progress", conversationTopic: "Cab Ride", topicImage: "chart.bar.xaxis",
                startTime: "10:30 PM", description: "Discussed drop-off location.", date: "4 Oct 2025", timeImage: "clock.badge.checkmark.fill"
            )
        ]
    }
    
    // MARK: - 2. Add New Action
    func addAction(_ action: RoutineConversation) {
        allActions.append(action)
    }
    
    // MARK: - 3. Get Flat List (For Home Screen)
    // Returns list sorted by time, ignoring categories
    func getAllActions() -> [RoutineConversation] {
        return allActions.sorted { compareTimes(time1: $0.startTime, time2: $1.startTime) }
    }
    
    // MARK: - 4. Get Grouped Sections (For Quick Actions Screen)
    func getGroupedSections() -> [RoutineSection] {
        // A. Group by Category Title
        let groupedDictionary = Dictionary(grouping: allActions) { $0.categoryTitle }
        
        // B. Map to Sections and Sort
        return groupedDictionary.map { (key, value) in
            
            // C. Sort Items INSIDE the category by TIME
            let sortedItems = value.sorted { (item1, item2) -> Bool in
                return compareTimes(time1: item1.startTime, time2: item2.startTime)
            }
            
            return RoutineSection(category: key, items: sortedItems)
        }
        // D. Sort Categories Alphabetically (Family -> Friends -> Office)
        .sorted { $0.category < $1.category }
    }
    
    // MARK: - 5. Time Comparator Helper
    // Converts "9:30 AM" strings to Dates for comparison
    private func compareTimes(time1: String, time2: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        guard let d1 = formatter.date(from: time1),
              let d2 = formatter.date(from: time2) else {
            return false // Keep original order if format fails
        }
        return d1 < d2
    }
}
