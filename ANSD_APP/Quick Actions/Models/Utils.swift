//
//  Utils.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 22/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//
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
    case "create":                     return .systemBlue
    case "quick captions", "quick captioning": return .systemBlue
    case "group-join", "group join":           return .black
    case "group-new", "group new":             return .black

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
    case "doctor", "health", "hospital", "medical", "appointment": return "cross.case.fill"
    case "food", "lunch", "dinner", "breakfast", "restaurant": return "fork.knife"
    case "coffee", "tea", "cafe": return "cup.and.saucer.fill"
    case "chat", "talk", "discussion": return "bubble.left.and.bubble.right.fill"
    default:
        let symbols = [
            "star.fill", "bolt.fill", "bookmark.fill", "flag.fill",
            "bell.fill", "flame.fill", "paperplane.fill", "cube.fill",
            "leaf.fill", "sparkles", "drop.fill", "moon.fill"
        ]
        let hash = abs(name.hashValue)
        return symbols[hash % symbols.count]
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

// Function - Converts a time string (e.g., "2:30 PM") into a Date object for the current day.
func getDate(from timeString: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    guard let timeDate = formatter.date(from: timeString) else { return nil }
    let calendar = Calendar.current
    let now = Date()
    let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
    return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: now)
}

import FirebaseAuth

class QuickActionAccess {
    static func verifyAccess(for item: RoutineConversation, over vc: UIViewController, onSuccess: @escaping () -> Void) {
        let currentUID = Auth.auth().currentUser?.uid
        if item.hostUID == currentUID {
            onSuccess() // Host bypasses room code
            return
        }

        let safeCode = item.roomCode ?? ""
        if safeCode.isEmpty {
            onSuccess()
            return
        }

        let defaultsKey = "joined_qa_\(item.id)"
        if UserDefaults.standard.bool(forKey: defaultsKey) {
            onSuccess()
            return
        }

        let alert = UIAlertController(title: "Enter Room Code", message: "Please enter the room code to join this Quick Action session.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Room Code"
            tf.keyboardType = .default
            tf.autocapitalizationType = .allCharacters
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Join", style: .default) { _ in
            let enteredCode = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if enteredCode.lowercased() == safeCode.lowercased() {
                UserDefaults.standard.set(true, forKey: defaultsKey)
                onSuccess()
            } else {
                let errorAlert = UIAlertController(title: "Incorrect Code", message: "The code you entered is incorrect.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                vc.present(errorAlert, animated: true)
            }
        })

        vc.present(alert, animated: true)
    }
}
