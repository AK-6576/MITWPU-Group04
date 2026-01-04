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
            RoutineItem(title: "Scrum Meet", time: "09:30 - 10:30 AM", notes: ""),
            RoutineItem(title: "Team Review", time: "12:00 - 01:30 PM", notes: ""),
            RoutineItem(title: "Board Review", time: "03:00 - 05:00 PM", notes: ""),
            RoutineItem(title: "EOD Report", time: "05:15 - 06:00 PM", notes: "")
        ]
        
    }
    
        
        static func getMockData1() -> [RoutineItem] {
            return [
                RoutineItem(
                    title: "Breakfast",
                    time: "08:00 - 09:00 AM",
                    notes: ""
                ),
                RoutineItem(
                    title: "Team Review",
                    time: "12:00 - 01:30 PM",
                    notes: ""
                ),
                RoutineItem(
                    title: "Board Review",
                    time: "03:00 - 05:00 PM",
                    notes: ""
                ),
                RoutineItem(
                    title: "Dinner",
                    time: "07:00 - 08:30 PM",
                    notes: ""
                )
            ]
        }
}
