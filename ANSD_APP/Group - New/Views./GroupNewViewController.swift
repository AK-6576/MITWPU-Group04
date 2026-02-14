import UIKit
import AVFoundation
import Speech

class GroupNewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    // MARK: - Properties
    private let speechManager = SpeechManager()
    private let firebase = FirebaseManager.shared // Using the Manager
    
    var isRecording = false
    var isPaused = false
    var isHost = true
    var selectedLanguageCode = "en-US"
    var otherPersonName = "Person 1"
    
    var messages: [GroupNewChatMessage] = []
    var currentSessionID: String = ""
    let currentUserID = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownUser"
    let myName = UIDevice.current.name
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        
        // Initial Room Setup (Defaults to Host)
        self.currentSessionID = "\(Int.random(in: 1000...9999))"
        startSession()
        
        setupJoinNotification()
    }
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
            layout.minimumLineSpacing = 10
        }
    }

    private func startSession() {
        self.title = "Host: \(currentSessionID)"
        self.messages.removeAll()
        
        // Use the Manager to connect
        firebase.setupSession(id: currentSessionID, isHost: isHost)
        
        // Listen for messages via the Manager
        firebase.observeMessages { [weak self] data in
            self?.handleIncomingFirebaseData(data)
        }
    }

    // MARK: - Firebase Handling
    private func handleIncomingFirebaseData(_ data: [String: Any]) {
        guard let senderID = data["senderID"] as? String,
              senderID != self.currentUserID else { return }

        let text = data["text"] as? String ?? ""
        let senderName = data["sender"] as? String ?? "Other"
        
        let newMessage = GroupNewChatMessage(text: text, isIncoming: true, sender: senderName, senderID: senderID)

        DispatchQueue.main.async {
            self.messages.append(newMessage)
            self.collectionView.reloadData()
            self.scrollToBottom()
        }
    }

    // MARK: - Transcription Actions
    @IBAction func didTapMicButton(_ sender: UIButton) {
        if !isRecording {
            startAudioAndTranscription()
        } else {
            stopAudioAndTranscription()
        }
        isRecording = !isRecording
    }
    
    private func startAudioAndTranscription() {
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
    }
    
    private func stopAudioAndTranscription() {
        stopLiveTranscription()
        micButton.tintColor = .systemBlue
        micButton.setImage(UIImage(systemName: "mic"), for: .normal)
    }

    func startLiveTranscription() {
        let newMessage = GroupNewChatMessage(text: "Listening...", isIncoming: false, sender: self.myName, senderID: currentUserID)
        self.messages.append(newMessage)
        
        let lastIndex = IndexPath(item: self.messages.count - 1, section: 0)
        self.collectionView.insertItems(at: [lastIndex])
        self.scrollToBottom()

        speechManager.startTranscribing(languageCode: self.selectedLanguageCode) { [weak self] transcribedText in
            guard let self = self, !self.messages.isEmpty else { return }
            
            let lastIdx = self.messages.count - 1
            self.messages[lastIdx].text = transcribedText
            
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.collectionView.reloadItems(at: [IndexPath(item: lastIdx, section: 0)])
                    self.scrollToBottom()
                }
            }
        }
    }
    
    func stopLiveTranscription() {
        speechManager.stopTranscribing()
        
        guard let lastMsg = messages.last else { return }
        let cleanedText = lastMsg.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedText.isEmpty || cleanedText == "Listening..." {
            removeLastGhostBubble()
            return
        }
        
        // Use the Manager to send
        firebase.send(text: lastMsg.text, sender: self.myName, senderID: self.currentUserID)
    }

    private func removeLastGhostBubble() {
        messages.removeLast()
        let lastIndexPath = IndexPath(item: messages.count, section: 0)
        if collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [lastIndexPath])
            })
        }
    }

    // MARK: - Actions & Navigation
    @IBAction func didTapPauseButton(_ sender: UIButton) {
        isPaused = !isPaused
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imgName = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
        
        if isPaused && isRecording {
            didTapMicButton(micButton) // Toggle off
        }
    }
    
    @IBAction func didTapStopButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "End Session?", message: "This will stop transcription and generate a summary.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "End Session", style: .destructive) { _ in
            if self.isRecording { self.stopAudioAndTranscription() }
            self.firebase.stop() // Cleanup Firebase
            self.navigateToSummary()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func navigateToSummary() {
        let storyboard = UIStoryboard(name: "Group-New", bundle: nil)
        if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
           let summaryVC = summaryNav.topViewController as? GroupNewSummaryViewController {
            summaryVC.transcriptMessages = self.messages
            summaryNav.modalPresentationStyle = .pageSheet
            self.present(summaryNav, animated: true)
        }
    }

    // MARK: - CollectionView Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        let isIncoming = (message.senderID != self.currentUserID)
        
        if isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IncomingCell", for: indexPath) as! GroupNewIncomingCell
            cell.messageLabel.text = message.text
            cell.nameLabel.text = message.sender
            cell.onLabelTapped = { [weak self] in self?.showRenameAlert() }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutgoingCell", for: indexPath) as! GroupNewOutgoingCell
            cell.messageLabel.text = message.text
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = messages[indexPath.row].text
        let approxWidth = collectionView.frame.width - 100
        let size = CGSize(width: approxWidth, height: 1000)
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let estimatedFrame = NSString(string: text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        return CGSize(width: collectionView.frame.width, height: estimatedFrame.height + 60)
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        collectionView.scrollToItem(at: IndexPath(item: messages.count - 1, section: 0), at: .bottom, animated: true)
    }

    // MARK: - Other UI Helpers (Rename/Join/Share)
    private func setupJoinNotification() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("JoinRoom"), object: nil, queue: .main) { [weak self] notification in
            if let roomID = notification.object as? String {
                self?.isHost = false
                self?.currentSessionID = roomID
                self?.startSession()
                self?.collectionView.reloadData()
            }
        }
    }

    func showRenameAlert() {
        let alert = UIAlertController(title: "Rename Speaker", message: "Enter new name:", preferredStyle: .alert)
        alert.addTextField { $0.text = self.otherPersonName }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                self.otherPersonName = name
                for i in 0..<self.messages.count where self.messages[i].isIncoming {
                    self.messages[i].sender = name
                }
                self.collectionView.reloadData()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @IBAction func addPersonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Add Participant", message: "Share code: \(currentSessionID)", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Share Invitation Link", style: .default) { _ in self.shareRoomInvitation() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func shareRoomInvitation() {
        let invite = "Join my session!\nLink: ansdapp://join/\(currentSessionID)\nCode: \(currentSessionID)"
        let activityVC = UIActivityViewController(activityItems: [invite], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}
