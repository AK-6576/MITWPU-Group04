//
//  RoutineData.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 27/11/25.
//

import Foundation

class RoutineRepository1 {
    
    static func getMockData1() -> [FamilyRoutineItem] {
        return [
            // 1. Morning Routine
            FamilyRoutineItem(
                title: "Breakfast",
                time: "08:00 - 09:00 AM",
                notes: ""
            ),
            
            // 2. Mid-day check-in (Who is eating where, picking up groceries, etc.)
            FamilyRoutineItem(
                title: "Lunch Coordination",
                time: "12:00 - 01:00 PM",
                notes: ""
            ),
            
            // 3. Post-work/school catch up
            FamilyRoutineItem(
                title: "Evening Tea & Snacks",
                time: "04:30 - 05:30 PM",
                notes: ""
            ),
            
            // 4. End of day family time
            FamilyRoutineItem(
                title: "Dinner",
                time: "07:30 - 09:00 PM",
                notes: ""
            )
        ]
    }
}
