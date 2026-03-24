//
//  ProfileManager.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 18/03/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import UIKit

class ProfileManager {
    static let shared = ProfileManager()
    
    private let firstNameBase = "user_first_name"
    private let lastNameBase = "user_last_name"
    private let genderBase = "user_gender"
    private let dobBase = "user_dob"
    private let imageBase = "profileImage"
    
    private init() {}
    
    private var uidPrefix: String {
        if let uid = FirebaseManager.shared.currentUID {
            return "\(uid)_"
        }
        return ""
    }
    
    var firstName: String {
        get { UserDefaults.standard.string(forKey: "\(uidPrefix)\(firstNameBase)") ?? "" }
        set { 
            UserDefaults.standard.set(newValue, forKey: "\(uidPrefix)\(firstNameBase)")
            NotificationCenter.default.post(name: NSNotification.Name("ProfileNameUpdated"),
                                          object: nil,
                                          userInfo: ["name": newValue])
        }
    }
    
    var lastName: String {
        get { UserDefaults.standard.string(forKey: "\(uidPrefix)\(lastNameBase)") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "\(uidPrefix)\(lastNameBase)") }
    }
    
    var gender: String {
        get { UserDefaults.standard.string(forKey: "\(uidPrefix)\(genderBase)") ?? "Select" }
        set { UserDefaults.standard.set(newValue, forKey: "\(uidPrefix)\(genderBase)") }
    }
    
    var dob: Date {
        get { UserDefaults.standard.object(forKey: "\(uidPrefix)\(dobBase)") as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: "\(uidPrefix)\(dobBase)") }
    }
    
    var profileImage: UIImage? {
        get {
            if let data = UserDefaults.standard.data(forKey: "\(uidPrefix)\(imageBase)") {
                return UIImage(data: data)
            }
            return nil
        }
        set {
            if let data = newValue?.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(data, forKey: "\(uidPrefix)\(imageBase)")
                NotificationCenter.default.post(name: NSNotification.Name("ProfileImageUpdated"), object: newValue)
            }
        }
    }
}
