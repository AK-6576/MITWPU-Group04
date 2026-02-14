//
//  FamilyRoutineData.swift
//  ANSD_APP
//
//  Created by SDC-USER on 05/02/26.
//

import Foundation

class RoutineRepository {
    
    // This function tells the app what routines to show for each category
    static func getRoutineData(for category: ChatCategory) -> [RoutineItem] {
        // We return an empty list for now because we deleted the dummy data.
        // You can add real items here later!
        return []
    }
}

// These help the Storyboard find the right names
struct FamilyRepository {
    static func getMockData1() -> [RoutineItem] { return [] }
}
