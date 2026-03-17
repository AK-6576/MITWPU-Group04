//
//  VoiceProfileManager.swift
//  ANSD_APP
//
//  Created by SDC-USER on 04/03/26.
//

import Foundation
import SwiftData

class VoiceProfileManager {
    static let shared = VoiceProfileManager()

    private var context: ModelContext? {
        return DataManager.shared.context
    }
    
    private init() {}
    
    // MARK: - Fetch Profile
    func getVoiceProfile(byUID ownerUID: String) -> VoiceProfile? {
        guard let context = context else { return nil }
        
        let descriptor = FetchDescriptor<VoiceProfile>(predicate: #Predicate { $0.ownerUID == ownerUID })
        
        do {
            let results = try context.fetch(descriptor)
            return results.first
        } catch {
            print("VoiceProfileManager: Failed to fetch Voice Profile. Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Save or Update Profile
    func saveVoiceProfile(ownerUID: String, name: String, embedding: [Float]) {
        guard let context = context else { return }
        
        if let existingProfile = getVoiceProfile(byUID: ownerUID) {
            // Update existing profile
            existingProfile.name = name
            existingProfile.embedding = embedding
            existingProfile.createdAt = Date()
        } else {
            // Create new profile
            let newProfile = VoiceProfile(ownerUID: ownerUID, name: name, embedding: embedding)
            context.insert(newProfile)
        }
        
        saveData()
    }
    
    // MARK: - Delete Profile (For resetting calibration)
    func deleteVoiceProfile(byUID ownerUID: String) {
        guard let context = context else { return }
        
        if let profileToDelete = getVoiceProfile(byUID: ownerUID) {
            context.delete(profileToDelete)
            saveData()
        }
    }
    
    // MARK: - Private Save Helper
    private func saveData() {
        guard let context = context else { return }
        do {
            try context.save()
            print("VoiceProfileManager: Successfully saved changes.")
        } catch {
            print("VoiceProfileManager: Failed to save context. Error: \(error.localizedDescription)")
        }
    }
}
