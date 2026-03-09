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
        return AppDelegate.dbContext
    }
    
    private init() {}
    
    // MARK: - Fetch Profile
    func getVoiceProfile(byId id: Int = 0) -> VoiceProfile? {
        guard let context = context else { return nil }
        
        let descriptor = FetchDescriptor<VoiceProfile>(predicate: #Predicate { $0.id == id })
        
        do {
            let results = try context.fetch(descriptor)
            return results.first
        } catch {
            print("VoiceProfileManager: Failed to fetch Voice Profile. Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Save or Update Profile
    func saveVoiceProfile(id: Int = 0, name: String, embedding: [Float]) {
        guard let context = context else { return }
        
        if let existingProfile = getVoiceProfile(byId: id) {
            // Update existing profile
            existingProfile.name = name
            existingProfile.embedding = embedding
            existingProfile.createdAt = Date()
        } else {
            // Create new profile
            let newProfile = VoiceProfile(id: id, name: name, embedding: embedding)
            context.insert(newProfile)
        }
        
        saveData()
    }
    
    // MARK: - Delete Profile (For resetting calibration)
    func deleteVoiceProfile(byId id: Int = 0) {
        guard let context = context else { return }
        
        if let profileToDelete = getVoiceProfile(byId: id) {
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
