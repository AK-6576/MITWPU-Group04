import Foundation

// MARK: - Protocol for Data Consistency
protocol RoutineItemProtocol {
    var title: String { get set }
    var time: String { get }
    var notes: String { get set }
}

// MARK: - Concrete Data Model
struct TestItem: RoutineItemProtocol {
    var title: String
    var time: String
    var notes: String
}

// MARK: - Routine Repository
class RoutineRepository {
    static func getRoutineData(for category: ChatCategory) -> [RoutineItemProtocol] {
        // This logic handles EVERY category dynamically based on the Enum passed
        switch category {
        case .family:
            return [TestItem(title: "Family Dinner", time: "7:00 PM", notes: "Vegetarian menu only")]
        case .friends:
            return [TestItem(title: "Gaming Session", time: "9:00 PM", notes: "Playing Valorant")]
        case .office:
            return [TestItem(title: "Team Sync", time: "10:00 AM", notes: "iOS Project update")]
        case .other:
            return [TestItem(title: "Gym Session", time: "6:00 AM", notes: "6k-7k steps target")]
        }
    }
}
