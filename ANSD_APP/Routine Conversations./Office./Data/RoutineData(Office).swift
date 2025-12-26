//
//  RoutineData.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 27/11/25.
//

import Foundation

class RoutineRepository {
    
    static func getMockData() -> [RoutineItem] {
        return [
            // We initialize 'notes' as an empty string for now
            RoutineItem(title: "Scrum Meet", time: "09:30 - 10:30 AM", notes: ""),
            RoutineItem(title: "Team Review", time: "12:00 - 01:30 PM", notes: ""),
            RoutineItem(title: "Board Review", time: "03:00 - 05:00 PM", notes: ""),
            RoutineItem(title: "EOD Report", time: "05:15 - 06:00 PM", notes: "")
        ]
        
    }
    
        
        static func getMockData1() -> [RoutineItem] {
            return [
                // 1. Changed "Daily Check-In" -> "Breakfast" (Family Context)
                RoutineItem(
                    title: "Breakfast",
                    time: "08:00 - 09:00 AM",
                    notes: "" // Notes will be saved here if the user types them
                ),
                
                // 2. Work item
                RoutineItem(
                    title: "Team Review",
                    time: "12:00 - 01:30 PM",
                    notes: ""
                ),
                
                // 3. Work item
                RoutineItem(
                    title: "Board Review",
                    time: "03:00 - 05:00 PM",
                    notes: ""
                ),
                
                // 4. Evening item
                RoutineItem(
                    title: "Dinner",
                    time: "07:00 - 08:30 PM",
                    notes: ""
                )
            ]
        }
}


