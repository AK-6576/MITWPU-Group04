import Foundation
import FirebaseDatabase
import FirebaseAuth

class FirebaseManager {
    
    static let shared = FirebaseManager()
    private let baseURL = "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app"
    private var ref: DatabaseReference?
    private let databaseRef = Database.database(url: "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    
    private init() {}

    // Helper to get current authenticated user's ID
    private var currentUID: String? {
        return Auth.auth().currentUser?.uid
    }

    // MARK: - Safety Helper
    /// Firebase keys cannot contain . # $ [ ]
    /// This replaces those characters with underscores to prevent app crashes.
    func sanitizeKey(_ key: String) -> String {
        return key.components(separatedBy: CharacterSet(charactersIn: ".#$[]"))
                  .joined(separator: "_")
    }
    // MARK: - Session Management
    
    /// Sets up the database reference for a specific room.
    /// - Parameters:
    ///   - hostUID: The UID of the room creator (Host).
    ///   - conversationID: The Room Code/ID.
    ///   - isHost: Boolean to determine if current user is starting the session.
    func setupSession(hostUID: String, conversationID: String, isHost: Bool) {
        let safeUID = sanitizeKey(hostUID)
        let safeConvID = sanitizeKey(conversationID)
        
        guard !safeUID.isEmpty, !safeConvID.isEmpty else {
            print("DEBUG: Firebase - Cannot setup session with empty IDs")
            return
        }

        // CRITICAL: Both Host and Joiner point to the HOST'S path to share messages
        // Path: users -> {hostUID} -> conversations -> {conversationID}
        self.ref = databaseRef.child("users").child(safeUID).child("conversations").child(safeConvID)
        
        if isHost {
            ref?.child("status").setValue("active")
            print("DEBUG: Firebase - Host created room at users/\(safeUID)/conversations/\(safeConvID)")
        } else {
            print("DEBUG: Firebase - Joiner connected to room at users/\(safeUID)/conversations/\(safeConvID)")
        }
    }

    func endSession() {
        // Only the host usually triggers this, but it updates the shared 'status' node
        ref?.child("status").setValue("ended")
    }

    func observeSessionStatus(completion: @escaping (String) -> Void) {
        ref?.child("status").observe(.value) { snapshot in
            if let status = snapshot.value as? String {
                completion(status)
            }
        }
    }

    // MARK: - Message Handling
    
    func observeMessages(completion: @escaping ([String: Any]) -> Void) {
        guard let sessionRef = ref?.child("messages") else {
            print("DEBUG: Firebase - Observer failed. Call setupSession first.")
            return
        }

        // .childAdded pulls all previous history immediately AND stays active for new messages.
        sessionRef.observe(.childAdded) { snapshot, _ in
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
        // This writes to the 'messages' node of whatever room was set in setupSession()
        ref?.child("messages").childByAutoId().setValue(dict)
    }

    // MARK: - Mirroring Logic (Sync across Users)
    
    /// Saves room metadata to the joiner's personal profile so it appears in their history.
    func linkConversationToJoiner(hostUID: String, conversationID: String, conversationTitle: String) {
        guard let myUID = currentUID else { return }
        
        let linkData: [String: Any] = [
            "id": conversationID,
            "title": conversationTitle,
            "isJoined": true,
            "sourceHostUID": hostUID, // Pointer back to the host's folder
            "lastUpdated": ServerValue.timestamp()
        ]
        
        let safeMyUID = sanitizeKey(myUID)
        let safeConvID = sanitizeKey(conversationID)
        
        // Save to the JOINER'S personal node: users/{joinerUID}/conversations/{roomID}
        databaseRef.child("users").child(safeMyUID).child("conversations").child(safeConvID).updateChildValues(linkData)
    }

    // MARK: - Conversation Sync (Local SwiftData to Personal Firebase)
    
    func saveConversationMetadata(_ conversation: Conversation) {
        guard let uid = currentUID else { return }
        let safeUID = sanitizeKey(uid)
        let safeConvID = sanitizeKey(conversation.id)

        let metadata: [String: Any] = [
            "id": conversation.id,
            "title": conversation.title,
            "details": conversation.details,
            "category": conversation.category,
            "icon": conversation.icon,
            "date": conversation.date,
            "startTime": conversation.startTime,
            "endTime": conversation.endTime,
            "isPinned": conversation.isPinned,
            "lastUpdated": ServerValue.timestamp()
        ]
        
        // This backups metadata to the logged-in user's own conversations folder
        databaseRef.child("users").child(safeUID).child("conversations").child(safeConvID).updateChildValues(metadata)
    }

    /// Saves a COMPLETE conversation including all messages and participants to history.
    func saveFullConversation(_ conversation: Conversation) {
        guard let uid = currentUID else { return }
        let safeUID = sanitizeKey(uid)
        let safeConvID = sanitizeKey(conversation.id)
        
        // 1. Prepare Metadata
        var metadata: [String: Any] = [
            "id": conversation.id,
            "title": conversation.title,
            "details": conversation.details,
            "category": conversation.category,
            "icon": conversation.icon,
            "date": conversation.date,
            "startTime": conversation.startTime,
            "endTime": conversation.endTime,
            "location": conversation.location,
            "isPinned": conversation.isPinned,
            "lastUpdated": ServerValue.timestamp()
        ]
        
        if let calendarDate = conversation.calendarDate {
            metadata["calendarDate"] = calendarDate.timeIntervalSince1970
        }
        
        if let notes = conversation.notes {
            metadata["notes"] = notes
        }
        
        // 2. Prepare Participants
        var participantsDict: [String: Any] = [:]
        if let participants = conversation.participants {
            for participant in participants {
                participantsDict[participant.id.uuidString] = [
                    "name": participant.name,
                    "summary": participant.summary,
                    "image": participant.image
                ]
            }
        }
        
        // 3. Prepare Messages
        var messagesDict: [String: Any] = [:]
        if let messages = conversation.messages {
            for message in messages {
                messagesDict[message.id.uuidString] = [
                    "text": message.text,
                    "senderName": message.senderName,
                    "senderId": message.senderId,
                    "isIncoming": message.isIncoming,
                    "isHighlighted": message.isHighlighted,
                    "isEdited": message.isEdited,
                    "timestamp": message.timestamp.timeIntervalSince1970
                ]
            }
        }
        
        let fullData: [String: Any] = [
            "metadata": metadata,
            "participants": participantsDict,
            "messages": messagesDict
        ]
        
        databaseRef.child("users").child(safeUID).child("history").child(safeConvID).setValue(fullData) { error, _ in
            if let error = error {
                print("Firebase: Failed to save full conversation: \(error.localizedDescription)")
            } else {
                print("Firebase: Successfully synced full transcript for: \(conversation.title)")
            }
        }
        
        // Also update the simple metadata list for quick fetching
        saveConversationMetadata(conversation)
    }
    
    /// Restores full conversation history (messages + participants) for a given ID
    func fetchFullConversation(uid: String, conversationID: String, completion: @escaping ([String: Any]?) -> Void) {
        let safeUID = sanitizeKey(uid)
        let safeConvID = sanitizeKey(conversationID)
        databaseRef.child("users").child(safeUID).child("history").child(safeConvID).observeSingleEvent(of: .value) { snapshot in
            completion(snapshot.value as? [String: Any])
        }
    }
    
    func stop() {
        ref?.removeAllObservers()
        ref = nil
    }

    // MARK: - Quick Action Sync Integration
    func saveQuickActionMetadata(_ action: RoutineConversation, hostUID: String) {
        let safeHost = sanitizeKey(hostUID)
        guard let code = action.roomCode else { return }
        let safeCode = sanitizeKey(code)

        let metadata: [String: Any] = [
            "id": action.id,
            "categoryTitle": action.categoryTitle,
            "conversationTopic": action.conversationTopic,
            "startTime": action.startTime,
            "status": action.status,
            "roomCode": code,
            "hostUID": safeHost,
            "iconName": action.iconName,
            "topicImage": action.topicImage,
            "timeImage": action.timeImage,
            "date": action.date ?? "",
            "description": action.description ?? "",
            "participantNames": action.participantNames,
            "lastUpdated": ServerValue.timestamp()
        ]
        
        // 1. Save to global Quick Actions registry so Joiners can look it up by code
        databaseRef.child("quick_actions").child(safeCode).setValue(metadata)
        
        // 2. Save to Host's Personal Folder
        databaseRef.child("users").child(safeHost).child("quick_actions").child(safeCode).setValue(metadata)
        
        // 3. Save to Participants' nodes so they can observe it (by name)
        for participant in action.participantNames {
            let safeParticipant = sanitizeKey(participant.trimmingCharacters(in: .whitespacesAndNewlines))
            if !safeParticipant.isEmpty {
                databaseRef.child("shared_quick_actions").child(safeParticipant).child(safeCode).setValue(metadata)
            }
        }
        
        // 4. Also save to each participant's own quick_actions node (by UID lookup)
        for participant in action.participantNames {
            let trimmed = participant.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lookupUID(byFirstName: trimmed) { [weak self] participantUID in
                    guard let self = self, let uid = participantUID else { return }
                    self.databaseRef.child("users").child(uid).child("quick_actions").child(safeCode).setValue(metadata)
                    print("DEBUG: Firebase - Shared Quick Action to participant UID: \(uid)")
                }
            }
        }
    }
    
    // MARK: - Generic Observers
    
    // Observes Quick Actions assigned specifically to the user (by checking their name against the shared node).
    func observeSharedQuickActions(forUserName userName: String, completion: @escaping ([String: Any]) -> Void) {
        let safeName = sanitizeKey(userName.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !safeName.isEmpty else { return }
        
        databaseRef.child("shared_quick_actions").child(safeName).observe(.childAdded) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                completion(value)
            }
        }
        
        databaseRef.child("shared_quick_actions").child(safeName).observe(.childChanged) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                completion(value)
            }
        }
    }
    
    // MARK: - Quick Action Presence Tracking
    
    /// Mark a user as "online" in a Quick Action room
    func setPresence(roomCode: String, userName: String) {
        let safeCode = sanitizeKey(roomCode)
        let safeName = sanitizeKey(userName)
        databaseRef.child("quick_actions").child(safeCode).child("presence").child(safeName).setValue(true)
    }
    
    /// Remove a user's presence when they leave the session
    func removePresence(roomCode: String, userName: String) {
        let safeCode = sanitizeKey(roomCode)
        let safeName = sanitizeKey(userName)
        databaseRef.child("quick_actions").child(safeCode).child("presence").child(safeName).removeValue()
    }
    
    /// Observe presence in real time — returns a Set of online sanitized user names
    func observePresence(roomCode: String, completion: @escaping (Set<String>) -> Void) {
        let safeCode = sanitizeKey(roomCode)
        databaseRef.child("quick_actions").child(safeCode).child("presence").observe(.value) { snapshot in
            var onlineNames = Set<String>()
            if let dict = snapshot.value as? [String: Any] {
                for key in dict.keys {
                    onlineNames.insert(key)
                }
            }
            completion(onlineNames)
        }
    }
    
    /// Stop observing presence for a room
    func stopObservingPresence(roomCode: String) {
        let safeCode = sanitizeKey(roomCode)
        databaseRef.child("quick_actions").child(safeCode).child("presence").removeAllObservers()
    }
    
    // MARK: - Authentication
    func registerRoom(code: String, hostUID: String) {
        let safeCode = sanitizeKey(code)
        databaseRef.child("room_registry").child(safeCode).setValue(["hostUID": hostUID])
    }

    /// Guest calls this to find the hostUID using only the Room Code
    func findHostID(for code: String, completion: @escaping (String?) -> Void) {
        let safeCode = sanitizeKey(code)
        databaseRef.child("room_registry").child(safeCode).child("hostUID").observeSingleEvent(of: .value) { snapshot in
            completion(snapshot.value as? String)
        }
    }
    
    func createAccount(details: [String: String], completion: @escaping (Result<User, Error>) -> Void) {
        guard let email = details["email"], let password = details["password"] else { return }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = authResult?.user else { return }

            let userProfile: [String: Any] = [
                "firstName": details["firstName"] ?? "",
                "lastName": details["lastName"] ?? "",
                "phone": details["phone"] ?? "",
                "email": email,
                "createdAt": ServerValue.timestamp()
            ]

            let safeUID = self.sanitizeKey(user.uid)
            self.databaseRef.child("users").child(safeUID).child("profile").setValue(userProfile) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(user))
                }
            }
        }
    }

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
    
    // MARK: - User Profile Fetching
    func fetchUserProfile(uid: String, completion: @escaping ([String: Any]?) -> Void) {
        let safeUID = sanitizeKey(uid)
        databaseRef.child("users").child(safeUID).child("profile").observeSingleEvent(of: .value) { snapshot in
            if let profileData = snapshot.value as? [String: Any] {
                completion(profileData)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Voice Profile Syncing
    func saveVoiceProfileMetadata(name: String, embedding: [Float]) {
        guard let uid = currentUID else { return }
        let safeUID = sanitizeKey(uid)
        
        let metadata: [String: Any] = [
            "name": name,
            "embedding": embedding,
            "lastUpdated": ServerValue.timestamp()
        ]
        
        databaseRef.child("users").child(safeUID).child("voice_profile").setValue(metadata) { error, _ in
            if let error = error {
                print("DEBUG: Firebase - Failed to save voice profile: \(error.localizedDescription)")
            } else {
                print("DEBUG: Firebase - Successfully saved voice profile for \(safeUID)")
            }
        }
    }
    
    func fetchVoiceProfileMetadata(uid: String, completion: @escaping ([String: Any]?) -> Void) {
        let safeUID = sanitizeKey(uid)
        databaseRef.child("users").child(safeUID).child("voice_profile").observeSingleEvent(of: .value) { snapshot in
            if let profileData = snapshot.value as? [String: Any] {
                completion(profileData)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Conversation History Fetch (Login Restore)
    func fetchConversationHistory(uid: String, completion: @escaping ([[String: Any]]) -> Void) {
        let safeUID = sanitizeKey(uid)
        databaseRef.child("users").child(safeUID).child("conversations").observeSingleEvent(of: .value) { snapshot in
            var conversations: [[String: Any]] = []
            if let dict = snapshot.value as? [String: Any] {
                for (_, value) in dict {
                    if let convo = value as? [String: Any] {
                        conversations.append(convo)
                    }
                }
            }
            completion(conversations)
        }
    }
    
    // MARK: - Quick Actions Fetch (Login Restore)
    func fetchQuickActions(uid: String, completion: @escaping ([[String: Any]]) -> Void) {
        let safeUID = sanitizeKey(uid)
        databaseRef.child("users").child(safeUID).child("quick_actions").observeSingleEvent(of: .value) { snapshot in
            var actions: [[String: Any]] = []
            if let dict = snapshot.value as? [String: Any] {
                for (_, value) in dict {
                    if let action = value as? [String: Any] {
                        actions.append(action)
                    }
                }
            }
            completion(actions)
        }
    }
    
    // MARK: - UID Lookup by Name
    func lookupUID(byFirstName name: String, completion: @escaping (String?) -> Void) {
        databaseRef.child("users").observeSingleEvent(of: .value) { snapshot in
            if let users = snapshot.value as? [String: Any] {
                for (uid, userData) in users {
                    if let userDict = userData as? [String: Any],
                       let profile = userDict["profile"] as? [String: Any],
                       let firstName = profile["firstName"] as? String,
                       firstName.lowercased() == name.lowercased() {
                        completion(uid)
                        return
                    }
                }
            }
            completion(nil)
        }
    }
    
    // MARK: - Sign Out & Data Purge
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            
            // No need to wipe SwiftData — data is now scoped per UID.
            // Just clear the in-memory Quick Actions array and user-preference keys.
            QuickActionsRepository.shared.clearAllActions()
            
            // Wipe generic user preferences to ensure no lingering UI state
            let defs = UserDefaults.standard
            let keysToRemove = ["user_first_name", "user_last_name", "user_gender", "user_dob", "profileImage"]
            for key in keysToRemove {
                defs.removeObject(forKey: key)
            }
            defs.synchronize()
            
            completion(.success(()))
        } catch let error {
            completion(.failure(error))
        }
    }
}
