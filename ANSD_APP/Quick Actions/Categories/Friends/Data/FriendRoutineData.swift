//
//  RoutineData.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 27/11/25.
//

import Foundation

class FriendRepository {
    static func getMockData1() -> [FriendRoutineItem] {
        return [
            FriendRoutineItem(
                title: "Coffee Runs",
                time: "09:00 AM",
                notes: "Sharing memes and daily updates."
            ),
            FriendRoutineItem(
                title: "Lunch Break Chat",
                time: "01:00 PM",
                notes: "Quick catch-up during work/school."
            ),
            FriendRoutineItem(
                title: "Gaming Session",
                time: "08:00 PM",
                notes: "Online lobby with the squad."
            ),
            FriendRoutineItem(
                title: "Late Night Talks",
                time: "11:30 PM",
                notes: "Random thoughts & venting."
            )
        ]
    }
}
