import Foundation

struct GroupNewChatMessage: Codable {
    var id: UUID?          // Supabase usually uses UUID or Int for IDs
    var text: String
    var sender: String
    var senderID: String
    var sessionID: String
    var createdAt: Date?
    
    // UI Helper (keep this outside CodingKeys so it doesn't look for it in the DB)
    var isIncoming: Bool = true

    enum CodingKeys: String, CodingKey {
        case id, text, sender
        case senderID = "sender_id"
        case sessionID = "session_id"
        case createdAt = "created_at"
    }
}
