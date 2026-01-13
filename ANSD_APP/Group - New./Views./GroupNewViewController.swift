//
//  GroupNewViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import FirebaseDatabase // 1. Add this import

class GroupNewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    let speechManager = SpeechManager()
    var isRecording = false             // Add this
    var selectedLanguageCode = "en-US" // Default
    var messages: [GNChatMessage] = []
    let fullConversation = GNChatData.fullConversation
    var currentMessageIndex = 0
    var isPaused = false
    var otherPersonName = "Person 1"
    
    // 2. Define Firebase properties
        let ref = Database.database(url: "https://ansd-f90fc-default-rtdb.asia-southeast1.firebasedatabase.app").reference().child("chat_sessions").child("session_01")
    // Change "Me" to a variable you can set
    var myName = UIDevice.current.name // This will use the iPhone's name (e.g., "Anshul's iPhone")
    let currentUserID = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownUser"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 1. REMOVE ref.removeValue() -> It deletes the chat every time a phone starts!
        
//        ref.removeValue()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            // Change this to a fixed size temporarily to see if bubbles appear
            layout.itemSize = CGSize(width: view.frame.width - 32, height: 80)
            layout.estimatedItemSize = .zero
            layout.minimumLineSpacing = 10
        }
        // IMPORTANT: Clear local messages on start so you don't see old test data
            self.messages.removeAll()
        observeFirebaseMessages()
    }
    // MARK: - Firebase Sync Logic
    func observeFirebaseMessages() {
        ref.observe(.childAdded) { [weak self] snapshot in
            guard let self = self,
                  let value = snapshot.value as? [String: Any],
                  let senderID = value["senderID"] as? String else { return }

            // STOP: If I am the one who sent this, ignore the Firebase update
            // because I already showed the blue bubble locally.
            if senderID == self.currentUserID {
                return
            }

            // Proceed to add the OTHER person's message
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
//
//    func processNextMessage() {
//        if currentMessageIndex >= fullConversation.count { return }
//        if isPaused { return }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
//            guard let self = self else { return }
//            if self.isPaused { return }
//            
//            let message = self.fullConversation[self.currentMessageIndex]
//            self.messages.append(message)
//            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
//            self.collectionView.insertItems(at: [indexPath])
//            self.scrollToBottom()
//            self.currentMessageIndex += 1
//            self.processNextMessage()
//        }
//    }
//    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        
        // KEY LOGIC: If the ID matches THIS phone, it's NOT incoming (it's Outgoing/Blue)
        let isMessageIncoming = (message.senderID != self.currentUserID)
        
        if isMessageIncoming {
            // OTHER PERSON (Grey Bubble)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IncomingCell", for: indexPath) as! GNIncomingCell
            cell.messageLabel.text = message.text
            cell.nameLabel.text = message.sender // Shows the other person's name
            
            cell.onLabelTapped = { [weak self] in
                self?.showRenameAlert()
            }
            return cell
        } else {
            // ME (Blue Bubble)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutgoingCell", for: indexPath) as! GNOutgoingCell
            cell.messageLabel.text = message.text
            return cell
        }
    }
    
    func showRenameAlert() {
        if !isPaused { togglePauseState() }
        
        let alert = UIAlertController(title: "Rename Speaker", message: "Enter name:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = self.otherPersonName
            tf.autocapitalizationType = .words
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self.otherPersonName = newName
                self.collectionView.reloadData()
            }
            self.togglePauseState()
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    @IBAction func didTapPauseButton(_ sender: UIButton) {
        togglePauseState()
    }
    
    func togglePauseState() {
        isPaused = !isPaused
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imgName = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
//        if !isPaused { processNextMessage() }
    }
    
    @IBAction func didTapStopButton(_ sender: UIButton) {
        if isRecording { didTapMicButton(micButton) }
        if !isPaused { togglePauseState() }
        
        let alert = UIAlertController(title: "End Session?", message: "Generate summary?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "End", style: .destructive, handler: { _ in
            let storyboard = UIStoryboard(name: "Group-New.", bundle: nil)
            
            if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
               let summaryVC = summaryNav.topViewController as? GNSummaryViewController {
                
                // --- DYNAMIC DATA LOGIC ---
                // 1. Get all unique names from the chat
                let uniqueNames = Set(self.messages.map { $0.sender })
                
                // 2. Create actual participant data based on what was said
                summaryVC.participantsData = uniqueNames.map { name in
                    let individualMessages = self.messages.filter { $0.sender == name }.map { $0.text }
                    let fullText = individualMessages.joined(separator: " ")
                    
                    return GNParticipantData(
                        name: name,
                        summary: fullText.isEmpty ? "No contribution recorded." : fullText
                    )
                }
                
                summaryNav.modalPresentationStyle = .pageSheet
                self.present(summaryNav, animated: true)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    @IBAction func didTapMicButton(_ sender: UIButton) {
        print("DEBUG: Mic Button Tapped!") // If you don't see this in Xcode, the button isn't connected
        if !isRecording {
            // Start Recording
            startLiveTranscription()
            micButton.tintColor = .systemRed
            micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        } else {
            // Stop Recording
            stopLiveTranscription()
            micButton.tintColor = .systemBlue
            micButton.setImage(UIImage(systemName: "mic"), for: .normal)
        }
        isRecording = !isRecording
    }
    
    // MARK: - Transcription Logic
    func startLiveTranscription() {
        let newMessage = GNChatMessage(text: "Listening...", isIncoming: false, sender: self.myName, senderID: currentUserID)
        self.messages.append(newMessage)
        
        let lastIndex = IndexPath(item: self.messages.count - 1, section: 0)
        self.collectionView.insertItems(at: [lastIndex])
        self.scrollToBottom()

        // --- UPDATED LINE BELOW ---
        speechManager.startTranscribing(languageCode: self.selectedLanguageCode) { [weak self] transcribedText in
            guard let self = self else { return }
            
            if !self.messages.isEmpty {
                self.messages[self.messages.count - 1] = GNChatMessage(
                    text: transcribedText,
                    isIncoming: false,
                    sender: self.myName, // Using self.myName for consistency
                    senderID: self.currentUserID
                )
                
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        self.collectionView.reloadItems(at: [lastIndex])
                        self.scrollToBottom()
                    }
                }
            }
        }
    }
    
    func stopLiveTranscription() {
        speechManager.stopTranscribing()
        
        if let lastMsg = messages.last {
            let messageToSend = GNChatMessage(
                text: lastMsg.text,
                isIncoming: false, // Local state
                sender: self.myName,
                senderID: self.currentUserID // THIS MUST BE PRESENT
            )
            
            // Save to Firebase
            ref.childByAutoId().setValue(messageToSend.toDictionary())
        }
    }
    
    func scrollToBottom() {
        guard messages.count > 0 else { return }
        let lastItem = IndexPath(item: messages.count - 1, section: 0)
        self.collectionView.scrollToItem(at: lastItem, at: .bottom, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - 32, height: 100)
    }
    
    @IBAction func addPersonTapped(_ sender: Any) {
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
}

