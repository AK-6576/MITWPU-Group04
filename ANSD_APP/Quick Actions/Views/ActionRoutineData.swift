//
//  ActionRoutineData.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// MARK: - Routine Data Structure
// Defines the data structure for routine items, including task details and completion status.
protocol RoutineItemProtocol {
    var title: String { get set }
    var time: String { get }
    var notes: String { get set }
}

// MARK: - Concrete Data Model
// Represents a concrete implementation of a routine item.
struct TestItem: RoutineItemProtocol {
    var title: String
    var time: String
    var notes: String
}

// MARK: - Routine Repository
// Manages the retrieval of routine data based on different categories.
class RoutineRepository {
    static func getRoutineData(for category: ChatCategory) -> [RoutineItemProtocol] {
        // This logic handles EVERY category dynamically based on the Enum passed
        switch category {
        case .family:
            return [TestItem(title: "Family Dinner", time: "7:00 PM", notes: "Vegetarian menu only")]
        case .friends:
            return [TestItem(title: "Gaming Session", time: "9:00 PM", notes: "Playing Valorant")]
        case .office:
            return [TestItem(title: "Team Sync", time: "10:00 AM", notes: "iOS Project update")]
        case .other:
            return [TestItem(title: "Gym Session", time: "6:00 AM", notes: "6k-7k steps target")]
        }
    }
}
