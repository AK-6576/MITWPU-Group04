//
//  Utils.swift
//  ANSD_APP


import UIKit

// MARK: - Color Logic (For Icons Only)

// Function - Determines and returns a specific UIColor based on the provided category name string, using a hash fallback for unknown categories.
func getColorForCategory(_ name: String) -> UIColor {
    let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
    
    switch lower {
    case "family", "date", "partner", "home": return .systemPink
    case "office", "work", "coding":          return .systemBlue
    case "friends", "gaming", "party":        return .systemGreen
    case "gym", "health", "medical":          return .systemOrange
    case "finance", "money", "bank":          return .systemMint
    case "create own...":                     return .systemBlue
        
    default:
        let palette: [UIColor] = [
            .systemYellow, .systemGreen, .systemTeal, .systemBlue,
            .systemIndigo, .systemPurple, .systemPink, .systemBrown
        ]
        let hash = abs(name.hashValue)
        return palette[hash % palette.count]
    }
}

// MARK: - Icon Logic

// Function - Retrieves the corresponding SF Symbol string identifier based on the provided category name, defaulting to a tag icon if no match is found.
func getSymbolForCategory(_ name: String) -> String {
    let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
    
    switch lower {
    case "friends", "hangout": return "person.2.fill"
    case "family", "home", "house": return "figure.2.and.child.holdinghands"
    case "date", "partner": return "heart.fill"
    case "office", "work", "meeting": return "briefcase.fill"
    case "school", "study", "class", "university": return "book.fill"
    case "coding", "dev", "tech": return "laptopcomputer"
    case "gym", "workout", "fitness": return "figure.run"
    case "groceries", "shopping": return "cart.fill"
    case "gaming": return "gamecontroller.fill"
    case "movie", "cinema": return "popcorn.fill"
    case "travel": return "airplane"
    case "bank", "finance": return "banknote.fill"
    default: return "tag.fill"
    }
}

// Function - Compares two time strings in either 12-hour or 24-hour format to determine if the first time occurs strictly before the second.
func compareTimes(time1: String, time2: String) -> Bool {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    
    formatter.dateFormat = "h:mm a"
    if let date1 = formatter.date(from: time1), let date2 = formatter.date(from: time2) {
        return date1 < date2
    }
    
    formatter.dateFormat = "HH:mm"
    if let date1 = formatter.date(from: time1), let date2 = formatter.date(from: time2) {
        return date1 < date2
    }
    
    return false
}
