import UIKit
import FirebaseDatabase
import AVFoundation
import Speech

class GroupJoinViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var GroupJoinCollectionView: UICollectionView!
    @IBOutlet weak var GroupJoinPauseButton: UIButton!
    @IBOutlet weak var GroupJoinMicButton: UIButton!
    @IBOutlet weak var GroupJoinEndButton: UIButton!
    
    // MARK: - Properties
    let speechManager = SpeechManager()
    var isRecording = false
    var selectedLanguageCode = "en-US"
    
    var currentSessionID: String = ""
    var messages: [GroupJoinChatMessage] = []
    var isPaused = false
    var otherPersonName = "Host"
    
    var ref: DatabaseReference!
    let currentUserID = UIDevice.current.identifierForVendor?.uuidString ?? "GuestUser"
    let myName = UIDevice.current.name

    override func viewDidLoad() {
        super.viewDidLoad()
        
        GroupJoinCollectionView.dataSource = self
        GroupJoinCollectionView.delegate = self
        
        // Setup UI Layout
        if let layout = GroupJoinCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: view.frame.width - 32, height: 80)
            layout.estimatedItemSize = .zero
            layout.minimumLineSpacing = 10
        }

        if currentSessionID.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showJoinRoomAlert()
            }
        } else {
            self.title = "Room \(currentSessionID)"
            setupFirebaseConnection()
        }
        // Optional: Update title to show the code so the host knows what to share
        self.title = "Host: \(currentSessionID)"
    }
    // MARK: - Join Logic
    func showJoinRoomAlert() {
        let alert = UIAlertController(title: "Join Session", message: "Enter the Room Code shared with you", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "4-Digit Code"
            textField.keyboardType = .numberPad
        }
        
        let joinAction = UIAlertAction(title: "Join", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if let code = alert.textFields?.first?.text, !code.isEmpty {
                self.currentSessionID = code
                self.title = "Room \(code)"
                self.messages.removeAll()
                self.setupFirebaseConnection() // Connect to the specific room
                self.GroupJoinCollectionView.reloadData()
            } else {
                // If they didn't enter a code, you might want to dismiss or show an error
                self.dismiss(animated: true)
            }
        }
        
        alert.addAction(joinAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        self.present(alert, animated: true)
    }

    // Add this as well to handle the Rename functionality used in your Cell logic
    func showRenameAlert() {
        let alert = UIAlertController(title: "Rename Speaker", message: "Enter name:", preferredStyle: .alert)
        alert.addTextField { $0.text = self.otherPersonName }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self?.otherPersonName = newName
                self?.GroupJoinCollectionView.reloadData()
            }
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    // MARK: - Firebase Logic
    func setupFirebaseConnection() {
        guard !currentSessionID.isEmpty else { return }
        let baseURL = "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app"
        self.ref = Database.database(url: baseURL).reference().child("chat_sessions").child(currentSessionID)
        observeFirebaseMessages()
    }
    
    func observeFirebaseMessages() {
        ref.observe(.childAdded) { [weak self] snapshot in
            guard let self = self,
                  let value = snapshot.value as? [String: Any],
                  let senderID = value["senderID"] as? String else { return }

            // Ignore if it's my own message (we show it locally during transcription)
            if senderID == self.currentUserID { return }

            let text = value["text"] as? String ?? ""
            let senderName = value["sender"] as? String ?? "Other"
            
            let newMessage = GroupJoinChatMessage(text: text, isIncoming: true, sender: senderName, senderID: senderID)

            DispatchQueue.main.async {
                self.messages.append(newMessage)
                self.GroupJoinCollectionView.reloadData()
                self.scrollToBottom()
            }
        }
    }

    // MARK: - Mic / Speech Logic (Matched to GroupNew)
    @IBAction func didTapMicButton(_ sender: UIButton) {
        // This MUST print. If it doesn't, your Storyboard connection is broken.
        print("DEBUG: Mic Button Tapped! Current State: \(isRecording ? "Recording" : "Not Recording")")
        
        if !isRecording {
            // Force stop any zombie engine instances
            speechManager.stopTranscribing()
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                // Set category for both play and record
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                // Start the actual logic
                self.startLiveTranscription()
                
                // UI Updates
                DispatchQueue.main.async {
                    self.GroupJoinMicButton.tintColor = .systemRed
                    self.GroupJoinMicButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
                }
                
                isRecording = true
            } catch {
                print("DEBUG: Audio Session error: \(error.localizedDescription)")
            }
        } else {
            stopLiveTranscription()
            
            DispatchQueue.main.async {
                self.GroupJoinMicButton.tintColor = .systemBlue
                self.GroupJoinMicButton.setImage(UIImage(systemName: "mic"), for: .normal)
            }
            
            isRecording = false
        }
    }

    func startLiveTranscription() {
        let newMessage = GroupJoinChatMessage(text: "Listening...", isIncoming: false, sender: self.myName, senderID: self.currentUserID)
        self.messages.append(newMessage)
        
        let lastIndex = IndexPath(item: self.messages.count - 1, section: 0)
        self.GroupJoinCollectionView.insertItems(at: [lastIndex])
        self.scrollToBottom()

        speechManager.startTranscribing(languageCode: self.selectedLanguageCode) { [weak self] transcribedText in
            guard let self = self else { return }
            
            let indexToUpdate = self.messages.count - 1
            guard indexToUpdate >= 0 else { return }
            
            self.messages[indexToUpdate] = GroupJoinChatMessage(
                text: transcribedText,
                isIncoming: false,
                sender: self.myName,
                senderID: self.currentUserID
            )
            
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.GroupJoinCollectionView.reloadItems(at: [IndexPath(item: indexToUpdate, section: 0)])
                    self.scrollToBottom()
                }
            }
        }
    }

    func stopLiveTranscription() {
        speechManager.stopTranscribing()
        
        // 1. Get the very last message on screen
        guard let lastMsg = messages.last else { return }
        
        // 2. Clean the text (remove accidental spaces)
        let cleanedText = lastMsg.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 3. SAFETY CHECK:
        // Only delete if the text is empty OR if it never changed from the placeholder
        if cleanedText.isEmpty || cleanedText == "Listening..." {
            print("DEBUG: No speech detected. Deleting empty bubble.")
            
            // Remove from local list so the blue pill disappears
            messages.removeLast()
            
            // Update the screen immediately
            let lastIndexPath = IndexPath(item: messages.count, section: 0)
            GroupJoinCollectionView.deleteItems(at: [lastIndexPath])
            
            return // We stop here. Nothing is sent to Firebase.
        }
        
        print("DEBUG: Saving message: \(cleanedText)")
        
        ref.childByAutoId().setValue(lastMsg.toDictionary()) { error, _ in
            if let error = error {
                print("DEBUG: Firebase Save Failed: \(error.localizedDescription)")
            } else {
                print("DEBUG: Message sent successfully!")
            }
        }
    }

    // MARK: - Control Buttons (Matched to GroupNew)
    @IBAction func didTapPauseButton(_ sender: UIButton) {
        isPaused = !isPaused
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imgName = isPaused ? "play.fill" : "pause.fill"
        GroupJoinPauseButton.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
    }
    
    // MARK: - Navigation Logic
        @IBAction func didTapStopButton(_ sender: UIButton) {
            // 1. Show Confirmation
            let alert = UIAlertController(title: "Leave Session?", message: "This will end transcription and generate a summary.", preferredStyle: .alert)
            
            let leaveAction = UIAlertAction(title: "End & Summarize", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                
                // 2. Stop Recording & Clean up
                if self.isRecording {
                    self.stopLiveTranscription()
                    self.isRecording = false
                }
                
                // 3. Navigate to Summary with Data
                self.navigateToSummary()
            }
            
            alert.addAction(leaveAction)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        }
        
        func navigateToSummary() {
            // NOTE: Ensure "Group-Join" matches your Storyboard filename exactly.
            // If it is in the same storyboard as GroupNew, use "Group-New."
            let storyboard = UIStoryboard(name: "Group-Join", bundle: nil)
            
            // Ensure Identifier "GJSummaryNavController" exists in Storyboard
            if let summaryNav = storyboard.instantiateViewController(withIdentifier: "GJSummaryNavController") as? UINavigationController,
               let summaryVC = summaryNav.topViewController as? GroupJoinSummaryViewController {
                
                // PASS THE REAL DATA
                summaryVC.transcriptMessages = self.messages
                summaryVC.conversationTitle = "Room \(self.currentSessionID)"
                
                summaryNav.modalPresentationStyle = .pageSheet
                self.present(summaryNav, animated: true, completion: nil)
            } else {
                print("DEBUG: Could not instantiate GJSummaryViewController. Check Storyboard ID.")
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


    // MARK: - Helpers
    func scrollToBottom() {
        guard messages.count > 0 else { return }
        let lastItem = IndexPath(item: messages.count - 1, section: 0)
        self.GroupJoinCollectionView.scrollToItem(at: lastItem, at: .bottom, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        let isMessageIncoming = (message.senderID != self.currentUserID)
        
        if isMessageIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IncomingCell", for: indexPath) as! GroupJoinIncomingCell
            cell.GroupJoinMessageLabel.text = message.text
            cell.GroupJoinNameLabel.text = message.sender
            cell.onLabelTapped = { [weak self] in self?.showRenameAlert() }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutgoingCell", for: indexPath) as! GroupJoinOutgoingCell
            cell.GroupJoinMessageLabel.text = message.text
            return cell
        }
    }
}
