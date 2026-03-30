import UIKit

extension Conversation {
    
    /// Returns a formatted date string (e.g., "January 15th")
    var formattedDisplayDate: String {
        if let date = self.calendarDate {
            let calendar = Calendar.current
            let day = calendar.component(.day, from: date)
            
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMMM"
            let month = monthFormatter.string(from: date)
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .ordinal
            let dayString = numberFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
            
            return "\(month) \(dayString)"
        }
        return self.date
    }
    
    /// Returns the system icon name based on the category
    var categoryIconName: String {
        switch category {
        case "Family":
            return "figure.2.and.child.holdinghands"
        case "Friends":
            return "person.3.fill"
        case "Office", "work":
            return "briefcase.fill"
        case "Medical", "Health":
            return "cross.case.fill"
        case "Quick Captions":
            return "waveform"
        case "Group-Join":
            return "person.bubble"
        case "Group-New":
            return "square.and.pencil"
        default:
            return "folder.fill"
        }
    }
    
    /// Returns the theme color for the category
    var categoryTintColor: UIColor {
        switch category {
        case "Family":
            return .systemPurple
        case "Friends":
            return .systemGreen
        case "Office", "work":
            return .systemBlue
        case "Medical", "Health":
            return .systemGreen
        case "Quick Captions":
            return .systemBlue
        case "Group-Join":
            return .black
        case "Group-New":
            return .black
        default:
            return .systemGray
        }
    }
    
    /// Returns the capitalized category name
    var displayCategory: String {
        return category.prefix(1).uppercased() + category.dropFirst()
    }
}
