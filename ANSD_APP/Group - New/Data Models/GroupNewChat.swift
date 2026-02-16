//
//  GroupNewChat.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import Foundation
import FirebaseDatabaseInternal

struct GroupNewChatMessage {
    var text: String
    let isIncoming: Bool
    var sender: String
    let senderID: String

    // Convert to Dictionary for Firebase
    func toDictionary() -> [String: Any] {
        return [
            "text": text,
            "sender": sender,
            "senderID": senderID,
            "timestamp": ServerValue.timestamp()
        ]
    }
}
