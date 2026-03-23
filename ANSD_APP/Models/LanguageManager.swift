//
//  LanguageManager.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 18/03/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import Speech

extension NSNotification.Name {
    static let languageDidChange = NSNotification.Name("languageDidChange")
}

class LanguageManager {
    static let shared = LanguageManager()
    
    // Key used to store the user's preference
    private let languageKey = "selected_speech_language"
    
    private init() {}
    
    /// Returns the currently selected Locale, defaulting to "en-US" if none is selected or available.
    var currentLocale: Locale {
        get {
            if let savedIdentifier = UserDefaults.standard.string(forKey: languageKey) {
                return Locale(identifier: savedIdentifier)
            }
            return Locale(identifier: "en-US") // Default
        }
        set {
            UserDefaults.standard.set(newValue.identifier, forKey: languageKey)
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    /// Returns the display name of the current language (e.g., "English (United States)")
    var currentLanguageDisplayName: String {
        return Locale.current.localizedString(forIdentifier: currentLocale.identifier) ?? currentLocale.identifier
    }
    
    /// Returns a list of supported languages as objects containing the name and locale.
    var supportedLanguages: [(name: String, locale: Locale)] {
        let locales = SFSpeechRecognizer.supportedLocales()
        
        var languageList: [(name: String, locale: Locale)] = []
        
        for locale in locales {
            // Get the localized display name for the locale (e.g., "English (United States)")
            if let displayName = Locale.current.localizedString(forIdentifier: locale.identifier) {
                languageList.append((name: displayName, locale: locale))
            } else {
                languageList.append((name: locale.identifier, locale: locale))
            }
        }
        
        // Sort alphabetically by the localized display name
        languageList.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        return languageList
    }
}
