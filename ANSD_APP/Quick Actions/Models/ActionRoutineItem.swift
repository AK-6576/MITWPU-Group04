//
//  ActionRoutineItem.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation

struct RoutineItem: Codable {
    var title: String
    var time: String
    var notes: String
    var isCompleted: Bool = false
    
    // Helper to create a new empty item
    static func new() -> RoutineItem {
        return RoutineItem(title: "New Routine", time: "09:00 AM", notes: "")
    }
}
