//
//  GroupNewViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import AVFoundation
import Speech
import Combine

class GroupNewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSpeechRecognizerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    // MARK: - Properties
    private let firebase = FirebaseManager.shared
    private let cleanupManager = TextCleanupManager()
    
    // Monolithic Speech Engine
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // State
    var isRecording = false
    var isPaused = false
    var isHost = true
    var selectedLanguageCode = "en-US"
    var otherPersonName = "Guest"
    
    var messages: [GroupNewChatMessage] = []
    var currentSessionID: String = ""
    let currentUserID = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownUser"
    let myName = UIDevice.current.name
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSpeechPermissions()
        setupAudioSession()
        
        // Initial Room Setup (Defaults to Host)
        if currentSessionID.isEmpty {
            self.currentSessionID = "\(Int.random(in: 1000...9999))"
        }
        
        startSession()
        setupJoinNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Auto-start recording immediately (Unmuted by default)
        if !isRecording {
            startRecording()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRecording()
    }
    
    // MARK: - UI Setup
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.minimumLineSpacing = 12
        }
        collectionView.keyboardDismissMode = .interactive
    }
    
    // MARK: - Audio & Speech Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            print("Audio Session Error: \(error)")
        }
    }
    
    private func setupSpeechPermissions() {
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.micButton.isEnabled = (authStatus == .authorized)
            }
        }
    }
    
    // MARK: - Speech Logic (Monolithic)
    
    private func startRecording() {
        // 1. Cancel existing tasks to ensure a fresh start
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 2. Add local "Listening..." bubble immediately
        addListeningBubble()
        
        // 3. Configure Audio Session & Request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        // Force On-Device for lower latency and no network endpoint errors
        if #available(iOS 13, *) {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0) // Safety removal
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
            updateMicButtonVisuals(isActive: true)
        } catch {
            print("Audio Engine Start Error: \(error)")
        }
        
        // 4. Start Recognition Task
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let rawText = result.bestTranscription.formattedString
                
                // Update local bubble with live text
                self.updateListeningBubble(with: rawText)
                
                // 5. Schedule Cleanup & Send (Debounced by 1 second)
                // When the user stops speaking for 1s, this block executes.
                self.cleanupManager.scheduleCleanup(text: rawText, at: 0) { _, cleanedText in
                    
                    // A. Send final cleaned text to Firebase
                    self.firebase.send(text: cleanedText, sender: self.myName, senderID: self.currentUserID)
                    
                    // B. Restart Recording to "cut" the bubble and start fresh
                    // We must stop the current engine/task to finalize this phrase.
                    if self.isRecording {
                        self.restartRecordingCycle()
                    }
                }
            }
            
            if error != nil {
                self.stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        
        removeListeningBubble()
        updateMicButtonVisuals(isActive: false)
    }
    
    private func restartRecordingCycle() {
        // Helper to seamlessly restart recording without UI flicker
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        
        // Remove the old bubble (Firebase will add the permanent one)
        removeListeningBubble()
        
        // Start fresh
        startRecording()
    }
    
    // MARK: - Bubble Logic
    
    private func addListeningBubble() {
        // Only add if not already present
        if let last = messages.last, last.text == "Listening..." && !last.isIncoming { return }
        
        let listeningMsg = GroupNewChatMessage(text: "Listening...", isIncoming: false, sender: myName, senderID: currentUserID)
        messages.append(listeningMsg)
        reloadDataAndScroll()
    }
    
    private func updateListeningBubble(with text: String) {
        // Find the last local message (placeholder) and update it
        if let index = messages.lastIndex(where: { !$0.isIncoming }) {
            messages[index].text = text
            // Optimization: Only reload the specific item to avoid flicker
            let indexPath = IndexPath(item: index, section: 0)
            UIView.performWithoutAnimation {
                self.collectionView.reloadItems(at: [indexPath])
            }
            scrollToBottom()
        }
    }
    
    private func removeListeningBubble() {
        // Remove any local placeholder that hasn't been finalized
        messages.removeAll { $0.text == "Listening..." && !$0.isIncoming }
        reloadDataAndScroll()
    }
    
    // MARK: - Firebase Logic
    
    private func startSession() {
        firebase.setupSession(id: currentSessionID, isHost: isHost)
        firebase.observeMessages { [weak self] data in
            guard let self = self else { return }
            
            if let text = data["text"] as? String,
               let sender = data["sender"] as? String,
               let senderID = data["senderID"] as? String {
                
                // If we receive a message from ourselves via Firebase, it means our "Send" was successful.
                // We ensure our local placeholder is gone before adding this "confirmed" message.
                if senderID == self.currentUserID {
                    self.removeListeningBubble()
                    // Re-add "Listening..." if we are still recording to show we are ready for next phrase
                    if self.isRecording {
                        self.addListeningBubble()
                    }
                }
                
                let isIncoming = senderID != self.currentUserID
                let msg = GroupNewChatMessage(text: text, isIncoming: isIncoming, sender: sender, senderID: senderID)
                
                self.messages.append(msg)
                self.reloadDataAndScroll()
            }
        }
    }
    
    private func setupJoinNotification() {
        // Example Notification Setup
        NotificationCenter.default.addObserver(forName: NSNotification.Name("UserJoined"), object: nil, queue: .main) { _ in
            // Handle UI updates if needed
        }
    }
    
    // MARK: - Actions
    
    @IBAction func micButtonTapped(_ sender: UIButton) {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        isPaused.toggle()
        let iconName = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setImage(UIImage(systemName: iconName), for: .normal)
        
        if isPaused {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @IBAction func endButtonTapped(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "End Session?", message: "Are you sure you want to end this conversation?", preferredStyle: .actionSheet)
                
                let endAction = UIAlertAction(title: "End Session", style: .destructive) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // 2. Stop Logic
                    self.stopRecording()
                    self.firebase.stop()
                    
                    // 3. Prepare & Present Summary Modally
                    let storyboard = UIStoryboard(name: "Group-New", bundle: nil)
                    if let summaryVC = storyboard.instantiateViewController(withIdentifier: "GroupNewSummaryViewController") as? GroupNewSummaryViewController {
                        
                        // Pass Data
                        summaryVC.transcriptMessages = self.messages
                        summaryVC.conversationTitle = "Session \(self.currentSessionID)"
                        
                        // 4. Wrap in Navigation Controller for Modal Presentation (PageSheet)
                        let nav = UINavigationController(rootViewController: summaryVC)
                        nav.modalPresentationStyle = .pageSheet
                        self.present(nav, animated: true, completion: nil)
                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                actionSheet.addAction(endAction)
                actionSheet.addAction(cancelAction)
                
                self.present(actionSheet, animated: true)
    }
    
    @IBAction func addPersonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Add Participant", message: "Share code: \(currentSessionID)", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Share Invitation Link", style: .default) { _ in self.shareRoomInvitation() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }
    
    func shareRoomInvitation() {
        let invite = "Join my session!\nLink: ansdapp://join/\(currentSessionID)\nCode: \(currentSessionID)"
        let activityVC = UIActivityViewController(activityItems: [invite], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func updateMicButtonVisuals(isActive: Bool) {
        let imageName = isActive ? "mic.fill" : "mic.slash.fill"
        let tintColor = isActive ? UIColor.systemRed : UIColor.label
        micButton.setImage(UIImage(systemName: imageName), for: .normal)
        micButton.tintColor = tintColor
    }
    
    private func reloadDataAndScroll() {
        collectionView.reloadData()
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let lastItem = IndexPath(item: messages.count - 1, section: 0)
        collectionView.scrollToItem(at: lastItem, at: .bottom, animated: true)
    }
    
    // MARK: - CollectionView DataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupNewIncomingCell", for: indexPath) as! GroupNewIncomingCell
            cell.configure(with: message)
            cell.onLabelTapped = { [weak self] in self?.showRenameAlert() }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupNewOutgoingCell", for: indexPath) as! GroupNewOutgoingCell
            cell.configure(with: message)
            return cell
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
}
