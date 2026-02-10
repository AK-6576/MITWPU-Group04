//
//  Chat.swift
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
    let senderID: String // Add this to distinguish between users

    // Convert to Dictionary for Firebase
    func toDictionary() -> [String: Any] {
        return [
            "text": text,
            "sender": sender,
            "senderID": senderID,
            "timestamp": ServerValue.timestamp() // Useful for sorting
        ]
    }
}

//struct GroupNewChatData {
//    static let fullConversation: [GroupNewChatMessage] = [
//        GroupNewChatMessage(
//            text: "Here are leaked photos of Spider-Man, from the set of Doomsday. Looks fantastic.",
//            isIncoming: true,
//            sender: "Peter Parker",
//            senderID: "user_peter"
//        ),
//        GroupNewChatMessage(
//            text: "I saw these......and they are definitely a photo-shop.",
//            isIncoming: false,
//            sender: "Me",
//            senderID: "user_me"
//        ),
//        GroupNewChatMessage(
//            text: "Of course they are.",
//            isIncoming: true,
//            sender: "Bruce Banner",
//            senderID: "user_bruce"
//        ),
//        GroupNewChatMessage(
//            text: "RPK is not always right, Peter.",
//            isIncoming: false,
//            sender: "Me",
//            senderID: "user_me"
//        ),
//        GroupNewChatMessage(
//            text: "But, DanielRPK has a clean track record. He is never wrong.",
//            isIncoming: true,
//            sender: "Peter Parker",
//            senderID: "user_peter"
//        ),
//        GroupNewChatMessage(
//            text: "Sounds like fan-fiction to me. GPT stuff.",
//            isIncoming: false,
//            sender: "Me",
//            senderID: "user_me"
//        ),
//        GroupNewChatMessage(
//            text: "Exactly. We cannot trust anything on the Internet anymore.",
//            isIncoming: true,
//            sender: "Bruce Banner",
//            senderID: "user_bruce"
//        ),
//        GroupNewChatMessage(
//            text: "Don't believe everything you see.",
//            isIncoming: false,
//            sender: "Me",
//            senderID: "user_me"
//        ),
//        GroupNewChatMessage(
//            text: "I guess. Still, let a man dream and live.",
//            isIncoming: true,
//            sender: "Peter Parker",
//            senderID: "user_peter"
//        ),
//        GroupNewChatMessage(
//            text: "Yeah yeah, I know. Let's go now. We have to meet Tom.",
//            isIncoming: false,
//            sender: "Me",
//            senderID: "user_me"
//        )
//    ]
//}
