import Foundation

struct RoutineItem: Codable {
    var title: String
    var time: String
    var notes: String
    var isCompleted: Bool = false
    
    // Helper to create a new empty item
    static func new() -> RoutineItem {
        return RoutineItem(title: "New Routine", time: "09:00 AM", notes: "")
    }
}
