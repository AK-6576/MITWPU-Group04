//
//  Utils.swift
//  ANSD_APP
//
//  Created by Daiwiik on 07/01/26.
//

import Foundation
import UIKit

// Now both screens can use this logic!
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
            .systemYellow,
            .systemGreen, .systemTeal, .systemBlue,
            .systemIndigo, .systemPurple, .systemPink, .systemBrown
        ]
        
        let hash = abs(name.hashValue)
        let index = hash % palette.count
        return palette[index]
    }
}
