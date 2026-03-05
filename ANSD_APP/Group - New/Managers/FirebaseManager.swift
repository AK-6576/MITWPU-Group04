//
//  FirebaseManager.swift
//  ANSD_APP
//
//  Created by Daiwiik on 10/02/26.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth // ADDED: Required for creating accounts and logging in

class FirebaseManager {
    
    static let shared = FirebaseManager()
    private let baseURL = "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app"
    private var ref: DatabaseReference?
    
    private init() {} // Prevents creating other instances
    
    // MARK: - Authentication Methods (NEW)
    
    /// Creates a new user account using Firebase Auth
    func createAccount(details: [String: String], completion: @escaping (Result<User, Error>) -> Void) {
        guard let email = details["email"], let password = details["password"] else {
            let error = NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing email or password."])
            completion(.failure(error))
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = authResult?.user else {
                let unknownError = NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during registration."])
                completion(.failure(unknownError))
                return
            }
            completion(.success(user))
        }
    }
    
    /// Logs in an existing user using Firebase Auth
    func loginUser(details: [String: String], completion: @escaping (Result<User, Error>) -> Void) {
        guard let email = details["email"], let password = details["password"] else {
            let error = NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing email or password."])
            completion(.failure(error))
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = authResult?.user else {
                let unknownError = NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during login."])
                completion(.failure(unknownError))
                return
            }
            completion(.success(user))
        }
    }
    
    // MARK: - Chat/Session Methods (ORIGINAL)
    
    /// Connect to a session.
    /// - Parameter isHost: If true, it wipes existing data for a fresh room.
    func setupSession(id: String, isHost: Bool) {
        self.ref = Database.database(url: baseURL).reference().child("chat_sessions").child(id)
        
        if isHost {
            ref?.removeValue()
            print("DEBUG: Firebase - Host started session \(id)")
        } else {
            print("DEBUG: Firebase - Guest joined session \(id)")
        }
    }
    
    /// Listens for new messages
    func observeMessages(completion: @escaping ([String: Any]) -> Void) {
        ref?.observe(.childAdded) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                completion(value)
            }
        }
    }
    
    /// Sends a transcription
    func send(text: String, sender: String, senderID: String) {
        let dict: [String: Any] = [
            "text": text,
            "sender": sender,
            "senderID": senderID,
            "timestamp": ServerValue.timestamp()
        ]
        ref?.childByAutoId().setValue(dict)
    }
    
    /// Stop listening (Cleanup)
    func stop() {
        ref?.removeAllObservers()
        ref = nil
    }
}
