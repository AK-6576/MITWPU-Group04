//
//  FamilyRoutineData.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 27/11/25.
//

import Foundation

class FamilyRepository {
    static func getMockData1() -> [FamilyRoutineItem] {
        return [
            FamilyRoutineItem(
                title: "Breakfast",
                time: "08:00 AM",
                notes: ""
            ),
            FamilyRoutineItem(
                title: "Lunch Coordination",
                time: "12:00 PM",
                notes: ""
            ),
            FamilyRoutineItem(
                title: "Evening Tea & Snacks",
                time: "04:30 PM",
                notes: ""
            ),
            FamilyRoutineItem(
                title: "Dinner",
                time: "07:30 PM",
                notes: ""
            )
        ]
    }
}
