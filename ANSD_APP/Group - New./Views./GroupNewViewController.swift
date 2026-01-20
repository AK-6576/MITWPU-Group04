import UIKit
import FirebaseDatabase
import AVFoundation
import Speech

class GroupNewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    // MARK: - Properties
    let speechManager = SpeechManager()
    var isRecording = false
    var selectedLanguageCode = "en-US"
    var messages: [GNChatMessage] = []
    var isPaused = false
    var otherPersonName = "Person 1"
    
    var ref: DatabaseReference!
    var currentSessionID: String = ""
    var myName = UIDevice.current.name
    var isHost = true // Default to true when starting a new session
    let currentUserID = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownUser"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Setup UI Layout
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                // Use automaticSize to let constraints determine the height
                layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
                layout.minimumLineSpacing = 10
            }

        self.messages.removeAll()

        // Generate a unique 4-digit code and connect to Firebase immediately
        self.currentSessionID = "\(Int.random(in: 1000...9999))"
        setupFirebaseRef()
        
        self.title = "Host: \(currentSessionID)"
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("JoinRoom"), object: nil, queue: .main) { [weak self] notification in
            if let roomID = notification.object as? String {
                self?.isHost = false // User is joining, NOT hosting
                self?.currentSessionID = roomID
                self?.messages.removeAll()
                self?.setupFirebaseRef()
                self?.collectionView.reloadData()
                self?.title = "Joined: \(roomID)"
            }
        }
    }
    
    func setupFirebaseRef() {
        let baseURL = "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app"
        self.ref = Database.database(url: baseURL).reference().child("chat_sessions").child(currentSessionID)
        
        // ONLY clear data if this user is the Host
        if isHost {
            self.ref.removeValue()
            print("DEBUG: Room Created as Host: \(currentSessionID)")
        } else {
            print("DEBUG: Joined Room as Guest: \(currentSessionID)")
        }
        
        observeFirebaseMessages()
    }
    
    // MARK: - Firebase Sync Logic
    func observeFirebaseMessages() {
        // 1. First, fetch all existing messages once
            ref.observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self, let allMessages = snapshot.value as? [String: [String: Any]] else { return }
                
                // Clear local array to avoid duplicates during initial sync
                self.messages.removeAll()
                
                // Sort and add existing messages here...
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.scrollToBottom()
                }
            }
        ref.observe(.childAdded) { [weak self] snapshot in
            guard let self = self,
                  let value = snapshot.value as? [String: Any],
                  let senderID = value["senderID"] as? String else { return }

            // Ignore if I am the one who sent this
            if senderID == self.currentUserID { return }

            let text = value["text"] as? String ?? ""
            let senderName = value["sender"] as? String ?? "Other"
            
            let newMessage = GNChatMessage(text: text, isIncoming: true, sender: senderName, senderID: senderID)

            DispatchQueue.main.async {
                self.messages.append(newMessage)
                self.collectionView.reloadData()
                self.scrollToBottom()
            }
        }
    }

    // MARK: - Transcription Actions
    @IBAction func didTapMicButton(_ sender: UIButton) {
        if !isRecording {
            // Setup Audio Session properly
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                startLiveTranscription()
                micButton.tintColor = .systemRed
                micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            } catch {
                print("DEBUG: Audio Session Error: \(error)")
            }
        } else {
            stopLiveTranscription()
            micButton.tintColor = .systemBlue
            micButton.setImage(UIImage(systemName: "mic"), for: .normal)
        }
        isRecording = !isRecording
    }
    
    func startLiveTranscription() {
        let newMessage = GNChatMessage(text: "Listening...", isIncoming: false, sender: self.myName, senderID: currentUserID)
        self.messages.append(newMessage)
        
        let lastIndex = IndexPath(item: self.messages.count - 1, section: 0)
        self.collectionView.insertItems(at: [lastIndex])
        self.scrollToBottom()

        speechManager.startTranscribing(languageCode: self.selectedLanguageCode) { [weak self] transcribedText in
            guard let self = self else { return }
            
            if !self.messages.isEmpty {
                let lastIdx = self.messages.count - 1
                self.messages[lastIdx] = GNChatMessage(
                    text: transcribedText,
                    isIncoming: false,
                    sender: self.myName,
                    senderID: self.currentUserID
                )
                
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        let indexPath = IndexPath(item: lastIdx, section: 0)
                        self.collectionView.reloadItems(at: [indexPath])
                        self.scrollToBottom()
                    }
                }
            }
        }
    }
    
    func stopLiveTranscription() {
            speechManager.stopTranscribing()
            
            // 1. Safety Check: Ensure a message exists
            guard let lastMsg = messages.last else { return }
            
            // 2. Clean the text to check for real content
            let cleanedText = lastMsg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 3. LOGIC FIX: If text is empty OR still says "Listening...", DELETE IT.
            if cleanedText.isEmpty || cleanedText == "Listening..." {
                print("DEBUG: Discarding empty voice message.")
                
                // Remove from local data source
                messages.removeLast()
                
                // Remove from the screen immediately (removes the "ghost" bubble)
                let lastIndexPath = IndexPath(item: messages.count, section: 0)
                
                // Perform the deletion safely
                if collectionView.numberOfItems(inSection: 0) > 0 {
                    collectionView.deleteItems(at: [lastIndexPath])
                }
                
                return // Stop here. Do not send to Firebase.
            }
            
            // 4. If we are here, the text is valid. Prepare to send.
            let dictToSend: [String: Any] = [
                "text": lastMsg.text,
                "sender": self.myName,
                "senderID": self.currentUserID,
                "timestamp": ServerValue.timestamp()
            ]
            
            // 5. Send to Firebase
            ref.childByAutoId().setValue(dictToSend) { [weak self] error, _ in
                if error == nil {
                    DispatchQueue.main.async {
                        // Update layout to fit the text exactly
                        self?.collectionView.collectionViewLayout.invalidateLayout()
                    }
                }
            }
        }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            // 1. Get the text for this message
            let text = messages[indexPath.row].text
            
            // 2. estimate the height based on the font you use in your cell (e.g., system font 17)
            let approximateWidth = collectionView.frame.width - 60 // Allow for padding/margins
            let size = CGSize(width: approximateWidth, height: 1000)
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)] // Make sure this matches your Cell Font
            
            let estimatedFrame = NSString(string: text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            // 3. Return dynamic height (+40 for padding)
            return CGSize(width: collectionView.frame.width, height: estimatedFrame.height + 40)
        }
    
    // MARK: - Helpers & CollectionView
    func scrollToBottom() {
        guard messages.count > 0 else { return }
        let lastItem = IndexPath(item: messages.count - 1, section: 0)
        self.collectionView.scrollToItem(at: lastItem, at: .bottom, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        let isMessageIncoming = (message.senderID != self.currentUserID)
        
        if isMessageIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IncomingCell", for: indexPath) as! GNIncomingCell
            cell.messageLabel.text = message.text
            cell.nameLabel.text = message.sender
            
            // Fix: Ensure [weak self] is handled clearly
            cell.onLabelTapped = { [weak self] in
                guard let self = self else { return }
                self.showRenameAlert()
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutgoingCell", for: indexPath) as! GNOutgoingCell
            cell.messageLabel.text = message.text
            return cell
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: collectionView.bounds.width - 32, height: 100)
//    }
    
    func showRenameAlert() {
        // 1. Pause transcription logic if needed while typing
        let wasRecordingBeforeAlert = isRecording
        if isRecording {
            // Optional: you can stop the mic or just pause UI updates
            // For now, let's just ensure we handle the name change safely
        }

        let alert = UIAlertController(
            title: "Rename Speaker",
            message: "This will change how the sender's name appears in your chat bubbles.",
            preferredStyle: .alert
        )
        
        // 2. Add text field and pre-fill with current name
        alert.addTextField { tf in
            tf.text = self.otherPersonName
            tf.placeholder = "Enter name"
            tf.autocapitalizationType = .words
        }
        
        // 3. Save Action
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text,
                  !newName.isEmpty else { return }
            
            // Update the local variable
            self.otherPersonName = newName
            
            // Update the 'sender' field in all existing messages that were from 'Other'
            // This ensures the UI updates immediately for old bubbles too
            for i in 0..<self.messages.count {
                if self.messages[i].isIncoming {
                    self.messages[i].sender = newName
                }
            }
            
            // Refresh the UI
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
        // 4. Cancel Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        // 5. Present the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addPersonTapped(_ sender: Any) {
            // 1. Create an alert to ask the user if they want to Share the code or Add manually
            let alert = UIAlertController(title: "Add Participant", message: "Invite others to join session 'session_01'", preferredStyle: .actionSheet)
            
            // 2. Share Room Link/Code Option
            alert.addAction(UIAlertAction(title: "Share Invitation Link", style: .default, handler: { _ in
                self.shareRoomInvitation()
            }))
            
            // 3. Your Existing Manual Add Logic
            alert.addAction(UIAlertAction(title: "Add from Contacts", style: .default, handler: { _ in
                self.presentParticipantSelection()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // Support for iPad
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            self.present(alert, animated: true)
        }
        
    // MARK: - Sharing Logic
    func shareRoomInvitation() {
        // 1. Get the current active session ID
        let roomID = self.currentSessionID
        
        // 2. Format the message exactly as you requested
        let invitationMessage = """
        I've started a live transcription session. 
        Click the link to join:
        ansdapp://join/\(roomID)
        
        Or enter Room Code: \(roomID)
        """
        
        // 3. Initialize the Activity View Controller (Share Sheet)
        let activityVC = UIActivityViewController(activityItems: [invitationMessage], applicationActivities: nil)
        
        // 4. Specifically for iPad support (prevents crashing)
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // 5. Present the share sheet
        self.present(activityVC, animated: true)
    }
        
        // MARK: - Helper to keep code clean
        func presentParticipantSelection() {
            let storyboard = UIStoryboard(name: "Group-New.", bundle: nil)
            
            if let selectionVC = storyboard.instantiateViewController(withIdentifier: "ParticipantSelectionViewController") as? ParticipantSelectionViewController {
                selectionVC.unavailableContacts = ["Peter Parker", "Bruce Banner"]
                selectionVC.onPeopleAdded = { newNames in
                    print("User added: \(newNames)")
                }
                
                let navWrapper = UINavigationController(rootViewController: selectionVC)
                navWrapper.modalPresentationStyle = .pageSheet
                if let sheet = navWrapper.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                }
                
                self.present(navWrapper, animated: true)
            }
        }
    
    func showJoinRoomAlert() {
        let alert = UIAlertController(title: "Join Session", message: "Enter the Room Code shared with you", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Room Code" }
        
        alert.addAction(UIAlertAction(title: "Join", style: .default, handler: { _ in
            if let code = alert.textFields?.first?.text, !code.isEmpty {
                self.isHost = false // Set this to false here too!
                self.currentSessionID = code
                self.messages.removeAll()
                self.setupFirebaseRef()
                self.collectionView.reloadData()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Host New", style: .cancel))
        self.present(alert, animated: true)
    }
}

