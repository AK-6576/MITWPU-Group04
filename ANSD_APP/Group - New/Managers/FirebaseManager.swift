//
//  FirebaseManager.swift
//  ANSD_APP
//
//  Created by Daiwiik on 10/02/26.
//

import Foundation
import FirebaseDatabase

class FirebaseManager {
    
    static let shared = FirebaseManager()
    private let baseURL = "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app"
    private var ref: DatabaseReference?
    
    private init() {} // Prevents creating other instances
    
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
