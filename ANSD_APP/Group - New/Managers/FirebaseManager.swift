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
        sessionRef.observe(.childAdded) { snapshot in
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
            "details": conversation.details ?? "",
            "category": conversation.category,
            "icon": conversation.icon,
            "date": conversation.date,
            "isPinned": conversation.isPinned,
            "lastUpdated": ServerValue.timestamp()
        ]
        
        // This backups metadata to the logged-in user's own conversations folder
        databaseRef.child("users").child(safeUID).child("conversations").child(safeConvID).updateChildValues(metadata)
    }
    
    func stop() {
        ref?.removeAllObservers()
        ref = nil
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
}
