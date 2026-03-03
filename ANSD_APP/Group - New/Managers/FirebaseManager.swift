//
//  FirebaseManager.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 10/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class FirebaseManager {
    
    static let shared = FirebaseManager()
    private let baseURL = "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app"
    private var ref: DatabaseReference?
    private let databaseRef = Database.database(url: "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    
    private init() {} // Prevents creating other instances
    
    /// 1. Update setupSession to include an initial status
    func setupSession(id: String, isHost: Bool) {
        self.ref = Database.database(url: baseURL).reference().child("chat_sessions").child(id)
        
        if isHost {
            // When host starts, set status to active
            ref?.setValue(["status": "active"])
            print("DEBUG: Firebase - Host started session \(id)")
        } else {
            print("DEBUG: Firebase - Guest joined session \(id)")
        }
    }

    /// 2. ADD THIS: Set the status to ended
    func endSession() {
        // This updates the 'status' key to 'ended' in Firebase
        ref?.updateChildValues(["status": "ended"])
    }

    /// 3. ADD THIS: Listen for the status change
    func observeSessionStatus(completion: @escaping (String) -> Void) {
        ref?.child("status").observe(.value) { snapshot in
            if let status = snapshot.value as? String {
                completion(status)
            }
        }
    }

    /// 4. UPDATE THIS: Keep messages in their own sub-folder
    /// This prevents 'status' updates from being confused with 'chat' updates
    func observeMessages(completion: @escaping ([String: Any]) -> Void) {
        ref?.child("messages").observe(.childAdded) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                completion(value)
            }
        }
    }

    func send(text: String, sender: String, senderID: String) {
        let dict: [String: Any] = [
            "text": text,
            "sender": sender,
            "senderID": senderID,
            "timestamp": ServerValue.timestamp()
        ]
        // Save under the 'messages' child node
        ref?.child("messages").childByAutoId().setValue(dict)
    }
    
    /// Stop listening (Cleanup)
    func stop() {
        ref?.removeAllObservers()
        ref = nil
    }
    
    /// Creates a new user in Firebase Auth and saves their details to the Database
    func createAccount(details: [String: String], completion: @escaping (Result<User, Error>) -> Void) {
        guard let email = details["email"], let password = details["password"] else { return }

        // 1. Create the user in Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = authResult?.user else { return }

            // 2. Prepare the user profile data for Realtime Database
            let userProfile: [String: Any] = [
                "firstName": details["firstName"] ?? "",
                "lastName": details["lastName"] ?? "",
                "phone": details["phone"] ?? "",
                "email": email,
                "createdAt": ServerValue.timestamp()
            ]

            // 3. Store the data under "users/uid"
            self.databaseRef.child("users").child(user.uid).setValue(userProfile) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(user))
                }
            }
        }
    }

    /// Signs in an existing user using Firebase Auth
    func loginUser(details: [String: String], completion: @escaping (Result<User, Error>) -> Void) {
        guard let email = details["email"], let password = details["password"] else {
            let error = NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Email or Password missing"])
            completion(.failure(error))
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let user = authResult?.user {
                completion(.success(user))
            }
        }
    }
}
