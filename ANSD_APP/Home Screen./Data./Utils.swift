//
//  Utils.swift
//  ANSD_APP
//

//
//  Utils.swift
//  ANSD_APP
//

import UIKit

// MARK: - Color Logic (For Icons Only)
func getColorForCategory(_ name: String) -> UIColor {
    let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
    
    switch lower {
    case "family", "date", "partner", "home": return .systemPink
    case "office", "work", "coding":          return .systemBlue
    case "friends", "gaming", "party":        return .systemOrange
    case "gym", "health", "medical":          return .systemGreen
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
func getSymbolForCategory(_ name: String) -> String {
    let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
    
    switch lower {
    case "friends", "hangout": return "person.2.fill"
    case "family", "home", "house": return "house.fill"
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
