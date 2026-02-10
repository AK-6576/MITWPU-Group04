import UIKit
import AVFoundation
import Speech

class GroupJoinViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - IBOutlets
    @IBOutlet weak var GroupJoinCollectionView: UICollectionView!
    @IBOutlet weak var GroupJoinPauseButton: UIButton!
    @IBOutlet weak var GroupJoinMicButton: UIButton!
    @IBOutlet weak var GroupJoinEndButton: UIButton!
    
    // MARK: - Properties
    private let speechManager = SpeechManager()
    private let firebase = FirebaseManager.shared // Using the Manager
    
    var isRecording = false
    var isPaused = false
    var selectedLanguageCode = "en-US"
    var currentSessionID: String = ""
    var otherPersonName = "Host"
    var messages: [GroupJoinChatMessage] = []
    
    let currentUserID = UIDevice.current.identifierForVendor?.uuidString ?? "GuestUser"
    let myName = UIDevice.current.name

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()

        if currentSessionID.isEmpty {
            // Delay slightly to ensure UI is ready before showing alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showJoinRoomAlert()
            }
        } else {
            startJoinSession()
        }
    }
    
    private func setupCollectionView() {
        GroupJoinCollectionView.dataSource = self
        GroupJoinCollectionView.delegate = self
        
        if let layout = GroupJoinCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
            layout.minimumLineSpacing = 10
        }
    }

    private func startJoinSession() {
        self.title = "Room: \(currentSessionID)"
        self.messages.removeAll()
        
        // Connect via Manager (isHost: false)
        firebase.setupSession(id: currentSessionID, isHost: false)
        
        // Listen for messages
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
        
        let newMessage = GroupJoinChatMessage(text: text, isIncoming: true, sender: senderName, senderID: senderID)

        DispatchQueue.main.async {
            self.messages.append(newMessage)
            self.GroupJoinCollectionView.reloadData()
            self.scrollToBottom()
        }
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
                self.startJoinSession()
                self.GroupJoinCollectionView.reloadData()
            } else {
                self.dismiss(animated: true)
            }
        }
        
        alert.addAction(joinAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        self.present(alert, animated: true)
    }

    // MARK: - Mic / Speech Logic
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
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            startLiveTranscription()
            
            GroupJoinMicButton.tintColor = .systemRed
            GroupJoinMicButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        } catch {
            print("DEBUG: Audio Session error: \(error.localizedDescription)")
        }
    }
    
    private func stopAudioAndTranscription() {
        stopLiveTranscription()
        GroupJoinMicButton.tintColor = .systemBlue
        GroupJoinMicButton.setImage(UIImage(systemName: "mic"), for: .normal)
    }

    func startLiveTranscription() {
        let newMessage = GroupJoinChatMessage(text: "Listening...", isIncoming: false, sender: self.myName, senderID: self.currentUserID)
        self.messages.append(newMessage)
        
        let lastIndex = IndexPath(item: self.messages.count - 1, section: 0)
        self.GroupJoinCollectionView.insertItems(at: [lastIndex])
        self.scrollToBottom()

        speechManager.startTranscribing(languageCode: self.selectedLanguageCode) { [weak self] transcribedText in
            guard let self = self, !self.messages.isEmpty else { return }
            
            let indexToUpdate = self.messages.count - 1
            self.messages[indexToUpdate].text = transcribedText
            
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
        
        guard let lastMsg = messages.last else { return }
        let cleanedText = lastMsg.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedText.isEmpty || cleanedText == "Listening..." {
            removeLastGhostBubble()
            return
        }
        
        // Use Manager to send
        firebase.send(text: lastMsg.text, sender: self.myName, senderID: self.currentUserID)
    }
    
    private func removeLastGhostBubble() {
        messages.removeLast()
        let lastIndexPath = IndexPath(item: messages.count, section: 0)
        if GroupJoinCollectionView.numberOfItems(inSection: 0) > 0 {
            GroupJoinCollectionView.performBatchUpdates({
                self.GroupJoinCollectionView.deleteItems(at: [lastIndexPath])
            })
        }
    }

    // MARK: - Actions
    @IBAction func didTapPauseButton(_ sender: UIButton) {
        isPaused = !isPaused
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imgName = isPaused ? "play.fill" : "pause.fill"
        GroupJoinPauseButton.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
        
        if isPaused && isRecording {
            didTapMicButton(GroupJoinMicButton)
        }
    }
    
    @IBAction func didTapStopButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "Leave Session?", message: "This will end transcription and generate a summary.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "End & Summarize", style: .destructive) { [weak self] _ in
            if self?.isRecording == true { self?.stopAudioAndTranscription() }
            self?.firebase.stop()
            self?.navigateToSummary()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
        
    func navigateToSummary() {
        let storyboard = UIStoryboard(name: "Group-Join", bundle: nil)
        if let summaryNav = storyboard.instantiateViewController(withIdentifier: "GJSummaryNavController") as? UINavigationController,
           let summaryVC = summaryNav.topViewController as? GroupJoinSummaryViewController {
            
            summaryVC.transcriptMessages = self.messages
            summaryVC.conversationTitle = "Room \(self.currentSessionID)"
            summaryNav.modalPresentationStyle = .pageSheet
            self.present(summaryNav, animated: true)
        }
    }

    // MARK: - CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        let isIncoming = (message.senderID != self.currentUserID)
        
        if isIncoming {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = messages[indexPath.row].text
        let approximateWidth = collectionView.frame.width - 60
        let size = CGSize(width: approximateWidth, height: 1000)
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let estimatedFrame = NSString(string: text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        return CGSize(width: collectionView.frame.width, height: estimatedFrame.height + 40)
    }

    func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let lastItem = IndexPath(item: messages.count - 1, section: 0)
        self.GroupJoinCollectionView.scrollToItem(at: lastItem, at: .bottom, animated: true)
    }

    func showRenameAlert() {
        let alert = UIAlertController(title: "Rename Speaker", message: "Enter name:", preferredStyle: .alert)
        alert.addTextField { $0.text = self.otherPersonName }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self?.otherPersonName = newName
                for i in 0..<(self?.messages.count ?? 0) where self?.messages[i].isIncoming == true {
                    self?.messages[i].sender = newName
                }
                self?.GroupJoinCollectionView.reloadData()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
}
