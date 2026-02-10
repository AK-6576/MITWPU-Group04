import Foundation
import FirebaseDatabaseInternal

struct GroupJoinChatMessage {
    var text: String
    let isIncoming: Bool
    var sender: String
    let senderID: String // Required for Firebase logic
    
    // Helper to convert to Dictionary for Firebase
    func toDictionary() -> [String: Any] {
        return [
            "text": text,
            "sender": sender,
            "senderID": senderID,
            "timestamp": ServerValue.timestamp()
        ]
    }
}

//struct GroupJoinChatData {
//    // Helper to generate a random ID for mock data
//    static func randomID() -> String {
//        return UUID().uuidString
//    }
//
//    static let fullConversation: [GroupJoinChatMessage] = [
//        GroupJoinChatMessage(
//            text: "Did everyone finish the assignment? It is due tomorrow and ma'am is strict.",
//            isIncoming: true,
//            sender: "Peter Parker",
//            senderID: "user_peter"
//        ),
//        GroupJoinChatMessage(
//            text: "Almost done! Just need to proofread.",
//            isIncoming: false,
//            sender: "Me",
//            senderID: "user_me"
//        ),
//        GroupJoinChatMessage(
//            text: "I haven't started... Help?",
//            isIncoming: true,
//            sender: "Bruce Banner",
//            senderID: "user_bruce"
//        )
//    ]
//}
