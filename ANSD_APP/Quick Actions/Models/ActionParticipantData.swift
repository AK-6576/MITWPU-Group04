import Foundation

// 1. This is the "Identity Card" for a person.
// Adding this here fixes the "Cannot find type ParticipantData" error.
struct ParticipantData {
    var name: String
    var summary: String
    var isCurrentUser: Bool = false
}

// 2. This is the "Data Shelf" (Repository)
class ParticipantRepository {
    
    // We use ChatCategory (the Enum) here so it matches your Summary Screen perfectly
    static func getParticipants(for category: ChatCategory) -> [ParticipantData] {
        switch category {
        case .family:
            return [
                ParticipantData(name: "Marie Parker", summary: "The organized host who keeps everyone fed."),
                ParticipantData(name: "Henry Parker", summary: "Always ready with a ride.")
            ]
        case .friends:
            return [
                ParticipantData(name: "Alex Jordan", summary: "The movie planner."),
                ParticipantData(name: "Sarah Miller", summary: "Always ready for food.")
            ]
        case .office:
            return [
                ParticipantData(name: "Julius Oppenheimer", summary: "Project lead."),
                ParticipantData(name: "Richard Feynman", summary: "Currently panicking.")
            ]
        case .other:
          return [  ParticipantData(name: "Julius Oppenheimer", summary: "Project lead."),
            ParticipantData(name: "Richard Feynman", summary: "Currently panicking.")
                    ]
        }
    }
}

// These are 'Nicknames' to help your old code stay happy
typealias FamilyParticipantData = ParticipantData
typealias FriendParticipantData = ParticipantData
typealias OfficeParticipantData = ParticipantData
