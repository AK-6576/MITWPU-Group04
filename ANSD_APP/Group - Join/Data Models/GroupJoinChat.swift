import Foundation

struct GroupJoinChatMessage: Codable {
    var id: UUID?          // 1. ADD THIS (Matches GroupNew)
    var text: String
    var sender: String
    var senderID: String
    var sessionID: String
    var createdAt: Date?
    
    // 2. SET TO TRUE. Incoming Realtime messages should default to true.
    var isIncoming: Bool = true

    enum CodingKeys: String, CodingKey {
        case id, text, sender // 3. ADD id HERE TOO
        case senderID = "sender_id"
        case sessionID = "session_id"
        case createdAt = "created_at"
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
