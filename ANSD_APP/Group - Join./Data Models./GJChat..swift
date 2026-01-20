import Foundation
import FirebaseDatabaseInternal

struct GJChatMessage {
    let text: String
    let isIncoming: Bool
    let sender: String
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

struct GJChatData {
    // Helper to generate a random ID for mock data
    static func randomID() -> String {
        return UUID().uuidString
    }

    static let fullConversation: [GJChatMessage] = [
        GJChatMessage(
            text: "Did everyone finish the assignment? It is due tomorrow and ma'am is strict.",
            isIncoming: true,
            sender: "Peter Parker",
            senderID: "user_peter"
        ),
        GJChatMessage(
            text: "Almost done! Just need to proofread.",
            isIncoming: false,
            sender: "Me",
            senderID: "user_me"
        ),
        GJChatMessage(
            text: "I haven't started... Help?",
            isIncoming: true,
            sender: "Bruce Banner",
            senderID: "user_bruce"
        )
    ]
}
