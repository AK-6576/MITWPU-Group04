import UIKit
import AVFoundation
import Speech
import Supabase // Use Supabase instead of Firebase
import Realtime

class GroupJoinViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var GroupJoinCollectionView: UICollectionView!
    @IBOutlet weak var GroupJoinMicButton: UIButton!
    
    // MARK: - Properties
        let speechManager = SpeechManager()
        let supabase = SupabaseManager.shared.client // Supabase Client
        var channel: RealtimeChannelV2?
        
        var isRecording = false
        var currentSessionID: String = ""
        var messages: [GroupJoinChatMessage] = [] // Ensure this model matches your DB columns
        var selectedLanguageCode = "en-US"
        let myName = UIDevice.current.name
    // Add these under your existing Properties section
    var otherPersonName: String = "Other Speaker"
    var isPaused = false
    // Replace the identifierForVendor line with this:
    var currentUserID: String {
        return supabase.auth.currentSession?.user.id.uuidString ?? "Guest"
    }
    
    @IBOutlet weak var GroupJoinPauseButton: UIButton! // Ensure this is connected in Storyboard
    
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
                    self.startJoinFlow()
                }
        // Optional: Update title to show the code so the host knows what to share
        self.title = "Host: \(currentSessionID)"
    }
    
    // MARK: - Join Logic
        func showJoinRoomAlert() {
            let alert = UIAlertController(title: "Join Session", message: "Enter the Room Code", preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "4-Digit Code"; $0.keyboardType = .numberPad }
            
            let joinAction = UIAlertAction(title: "Join", style: .default) { [weak self] _ in
                guard let self = self, let code = alert.textFields?.first?.text, !code.isEmpty else {
                    self?.dismiss(animated: true); return
                }
                self.currentSessionID = code
                self.startJoinFlow()
            }
            
            alert.addAction(joinAction)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in self?.dismiss(animated: true) })
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
    
    // MARK: - Supabase Logic (The Fetch + Sub Model)
    func fetchPreviousMessages() async {
        do {
            // FIX: Removed manual JSONDecoder and fixed the .execute().value chain
            let history: [GroupJoinChatMessage] = try await supabase
                .from("chat_messages")
                .select()
                .eq("session_id", value: currentSessionID)
                .order("created_at", ascending: true)
                .execute() // Call as a function
                .value     // Access the decoded data directly

            await MainActor.run {
                self.messages = history
                self.GroupJoinCollectionView.reloadData()
                self.scrollToBottom()
            }
        } catch {
            print("❌ Error fetching history: \(error)")
        }
    }
    
    func startJoinFlow() {
            self.title = "Room \(currentSessionID)"
            self.messages.removeAll()
            self.GroupJoinCollectionView.reloadData()
            
            // This is the core Pub/Sub entry point
            Task {
                await fetchPreviousMessages() // 1. Get History
                setupRealtimeSubscription()   // 2. Listen for New
            }
        }
    
    // MARK: - Speech Logic
        @IBAction func didTapMicButton(_ sender: UIButton) {
            if !isRecording {
                startLiveTranscription()
                GroupJoinMicButton.tintColor = .systemRed
                GroupJoinMicButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
                isRecording = true
            } else {
                stopLiveTranscription()
                GroupJoinMicButton.tintColor = .systemBlue
                GroupJoinMicButton.setImage(UIImage(systemName: "mic"), for: .normal)
                isRecording = false
            }
        }

    func setupRealtimeSubscription() {
        let newChannel = supabase.realtimeV2.channel("room_\(currentSessionID)")
        self.channel = newChannel
        
        let filter = "session_id=eq.\(currentSessionID)"
        
        newChannel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "chat_messages",
            filter: filter
        ) { [weak self] change in
            guard let self = self else { return }
            do {
                // Provide the decoder argument
                let newMessage = try change.decodeRecord(as: GroupJoinChatMessage.self, decoder: JSONDecoder())
                Task { await self.processIncomingMessage(newMessage) }
            } catch {
                print("❌ Realtime decoding error: \(error)")
            }
        }
        
        // IMPORTANT: You MUST call subscribe() to start receiving updates
        Task {
            try await newChannel.subscribe()
            print("✅ Subscribed to Realtime for room: \(currentSessionID)")
        }
    }
    
    func processIncomingMessage(_ newMessage: GroupJoinChatMessage) async {
        // Only add if it's not from us
        if newMessage.senderID != self.currentUserID {
            await MainActor.run {
                var incomingMsg = newMessage
                incomingMsg.isIncoming = true
                self.messages.append(incomingMsg)
                self.GroupJoinCollectionView.reloadData()
                self.scrollToBottom()
            }
        }
    }
    
    func startLiveTranscription() {
            // Local preview bubble
        let newMessage = GroupJoinChatMessage(
            text: "Listening...",
            sender: self.myName,
            senderID: self.currentUserID,
            sessionID: self.currentSessionID, // Added this
            createdAt: nil,                  // Added this
            isIncoming: false
        )
            self.messages.append(newMessage)
            self.GroupJoinCollectionView.reloadData()
            self.scrollToBottom()

            speechManager.startTranscribing(languageCode: self.selectedLanguageCode) { [weak self] text in
                guard let self = self, let lastIndex = self.messages.indices.last else { return }
                self.messages[lastIndex].text = text
                DispatchQueue.main.async {
                    self.GroupJoinCollectionView.reloadItems(at: [IndexPath(item: lastIndex, section: 0)])
                }
            }
        }

        func stopLiveTranscription() {
            let finalTranscribedText = speechManager.stopTranscribing()
            guard var lastMsg = messages.last else { return }
            
            if finalTranscribedText.isEmpty || finalTranscribedText == "Listening..." {
                messages.removeLast()
                GroupJoinCollectionView.reloadData()
                return
            }

            lastMsg.text = finalTranscribedText
            lastMsg.sessionID = self.currentSessionID // Ensure ID is attached
            
            Task {
                do {
                    try await supabase.from("chat_messages").insert(lastMsg).execute()
                } catch {
                    print("❌ Publish error: \(error)")
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
