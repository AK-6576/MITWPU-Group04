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
            print("VoiceProfileManager: Deleting existing voice profile for user \(ownerUID)...")
            saveData()
        }
    }

    // MARK: - Private Save Helper
    private func saveData() {
        guard let context = context else {
            print("VoiceProfileManager: ERROR - No ModelContext found for saveData")
            return
        }
        do {
            print("VoiceProfileManager: Attempting to save ModelContext...")
            try context.save()
            print("VoiceProfileManager: SUCCESS - Successfully saved changes to SwiftData.")
        } catch {
            print("VoiceProfileManager: ERROR - Failed to save context: \(error.localizedDescription)")
        }
    }
}
