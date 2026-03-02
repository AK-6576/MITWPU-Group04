//
//  GroupJoinViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import AVFoundation
import Speech
import Combine
import FoundationModels // Apple Intelligence

class GroupJoinViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSpeechRecognizerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var GroupJoinCollectionView: UICollectionView!
    @IBOutlet weak var GroupJoinPauseButton: UIButton!
    @IBOutlet weak var GroupJoinMicButton: UIButton!
    @IBOutlet weak var GroupJoinEndButton: UIButton!
    
    // MARK: - Properties
    private let firebase = FirebaseManager.shared
    private let cleanupManager = TextCleanupManager()
    
    // Apple Intelligence Model
    private let model = SystemLanguageModel.default
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var isRecording = false
    var isPaused = false
    var isHost = false
    var isRestarting = false
    
    var messages: [GroupJoinChatMessage] = []
    
    // Buffering State
    var consumedTranscriptOffset = 0
    
    // Data from Selection Screen
    var currentSessionID: String = ""
    var sessionTitle: String = "Session"
    
    let currentUserID = UIDevice.current.identifierForVendor?.uuidString ?? "GuestUser"
    let myName = UIDevice.current.name
    
    var otherPersonName = "Host"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSpeechPermissions()
        setupAudioSession()
        
        self.title = sessionTitle
        
        if !currentSessionID.isEmpty {
            startSession()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isRecording {
            startRecording()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRecording()
    }
    
    // MARK: - Setup
    private func setupCollectionView() {
        GroupJoinCollectionView.dataSource = self
        GroupJoinCollectionView.delegate = self
        if let layout = GroupJoinCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.minimumLineSpacing = 12
        }
    }
    
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
                self.GroupJoinMicButton.isEnabled = (authStatus == .authorized)
            }
        }
    }
    
    // MARK: - Speech Logic (Monolithic + Offset + AI Cleanup)
    private func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Reset offset
        consumedTranscriptOffset = 0
        addListeningBubble()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if #available(iOS 13, *) { request.requiresOnDeviceRecognition = true }
        recognitionRequest = request
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
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
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let fullString = result.bestTranscription.formattedString
                
                // Safety check
                if self.consumedTranscriptOffset > fullString.count {
                    self.consumedTranscriptOffset = 0
                }
                
                // Calculate Delta
                let index = fullString.index(fullString.startIndex, offsetBy: self.consumedTranscriptOffset)
                let newContent = String(fullString[index...])
                self.consumedTranscriptOffset = fullString.count
                
                guard !newContent.isEmpty else { return }
                
                // Update Bubble Logic
                if let lastIndex = self.messages.lastIndex(where: { !$0.isIncoming }) {
                    let currentText = self.messages[lastIndex].text
                    let baseText = (currentText == "Listening..." || currentText == "...") ? "" : currentText
                    let combinedText = baseText + newContent
                    
                    // CHECK LIMIT (3-4 Lines Logic)
                    if combinedText.count > MAX_BUBBLE_CHAR_LIMIT {
                        // 1. Finalize Current Bubble
                        self.messages[lastIndex].text = combinedText
                        self.GroupJoinCollectionView.reloadItems(at: [IndexPath(item: lastIndex, section: 0)])
                        
                        // 2. Trigger AI Cleanup for this bubble
                        self.processTextWithAppleIntelligence(text: combinedText, index: lastIndex)
                        
                        // 3. Start NEW Bubble
                        let newMsg = GroupJoinChatMessage(text: "...", isIncoming: false, sender: self.myName, senderID: self.currentUserID)
                        self.messages.append(newMsg)
                        self.reloadDataAndScroll()
                        
                    } else {
                        // JUST APPEND
                        self.messages[lastIndex].text = combinedText
                        self.GroupJoinCollectionView.reloadItems(at: [IndexPath(item: lastIndex, section: 0)])
                        self.scrollToBottom()
                    }
                    
                    // SILENCE DETECTION
                    self.cleanupManager.scheduleCleanup(text: "keepalive", at: 0) { _, _ in
                        
                        // Finalize bubble if silence detected
                        if let finalIndex = self.messages.lastIndex(where: { !$0.isIncoming }) {
                            let finalText = self.messages[finalIndex].text
                            if finalText != "Listening..." && finalText != "..." && !finalText.isEmpty {
                                // Trigger AI Cleanup
                                self.processTextWithAppleIntelligence(text: finalText, index: finalIndex)
                            }
                        }
                        
                        if self.isRecording {
                            self.restartRecordingCycle()
                        }
                    }
                }
            }
            
            if let error = error {
                if !self.isRestarting {
                    print("Speech Error: \(error)")
                    self.stopRecording()
                } else {
                    self.isRestarting = false
                }
            }
        }
    }
    
    // MARK: - Apple Intelligence Logic
    private func processTextWithAppleIntelligence(text: String, index: Int) {
        Task {
            do {
                let prompt = "Fix grammar and make concise: \(text)"
                let session = LanguageModelSession(model: model)
                let response = try await session.respond(to: prompt)
                let cleanedText = response.content
                
                await MainActor.run {
                    // Update Local UI
                    if index < self.messages.count {
                        self.messages[index].text = cleanedText
                        self.GroupJoinCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                        
                        // Send to Firebase
                        self.firebase.send(text: cleanedText, sender: self.myName, senderID: self.currentUserID)
                    }
                }
            } catch {
                print("Apple Intelligence Error: \(error)")
                // Fallback: Send raw text if AI fails
                await MainActor.run {
                    self.firebase.send(text: text, sender: self.myName, senderID: self.currentUserID)
                }
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
        isRestarting = true
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        
        removeListeningBubble()
        startRecording()
    }
    
    // MARK: - Bubble Logic
    private func addListeningBubble() {
        if let last = messages.last, last.text == "Listening..." && !last.isIncoming { return }
        let listeningMsg = GroupJoinChatMessage(text: "Listening...", isIncoming: false, sender: myName, senderID: currentUserID)
        messages.append(listeningMsg)
        reloadDataAndScroll()
    }
    
    private func updateListeningBubble(with text: String) {
        if let index = messages.lastIndex(where: { !$0.isIncoming }) {
            messages[index].text = text
            let indexPath = IndexPath(item: index, section: 0)
            UIView.performWithoutAnimation {
                self.GroupJoinCollectionView.reloadItems(at: [indexPath])
            }
            scrollToBottom()
        }
    }
    
    private func removeListeningBubble() {
        messages.removeAll { ($0.text == "Listening..." || $0.text == "...") && !$0.isIncoming }
        reloadDataAndScroll()
    }
    
    // MARK: - Firebase Logic
    private func startSession() {
        // 1. Initialize the session node in Firebase
        firebase.setupSession(id: currentSessionID, isHost: isHost)
        
        // 2. Listen for Global Session Status (NEW)
        // This allows the host to end the session for everyone
        firebase.observeSessionStatus { [weak self] status in
            guard let self = self else { return }
            if status == "ended" {
                print("DEBUG: Session ended by host. Transitioning to summary.")
                self.handleGlobalSessionEnd()
            }
        }
        
        // 3. Existing Message Observation Logic
        firebase.observeMessages { [weak self] data in
            guard let self = self else { return }
            
            if let text = data["text"] as? String,
               let sender = data["sender"] as? String,
               let senderID = data["senderID"] as? String {
                
                // Deduplication check: Don't add if we just sent this locally
                if senderID == self.currentUserID {
                    let lastFinalized = self.messages.last(where: { $0.text != "Listening..." && $0.text != "..." && !$0.isIncoming })
                    if let last = lastFinalized, last.text == text {
                        return
                    }
                }
                
                // Visual management for the "Listening..." bubble
                let isListeningPresent = (self.messages.last?.text == "Listening..." || self.messages.last?.text == "...") && !self.messages.last!.isIncoming
                
                if isListeningPresent {
                    self.removeListeningBubble()
                }
                
                // Create and append the new message bubble
                let msg = GroupJoinChatMessage(text: text, isIncoming: (senderID != self.currentUserID), sender: sender, senderID: senderID)
                self.messages.append(msg)
                self.reloadDataAndScroll()
                
                // Re-add the listening indicator if user is still recording
                if isListeningPresent && self.isRecording {
                    self.addListeningBubble()
                }
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func micButtonTapped(_ sender: UIButton) {
        isRecording ? stopRecording() : startRecording()
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        isPaused.toggle()
        let iconName = isPaused ? "play.fill" : "pause.fill"
        GroupJoinPauseButton.setImage(UIImage(systemName: iconName), for: .normal)
        isPaused ? stopRecording() : startRecording()
    }
    
    @IBAction func endButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "End Session?",
            message: "This will end the session for all participants and show the summary.",
            preferredStyle: .alert
        )
        
        let endAction = UIAlertAction(title: "End Session", style: .destructive) { [weak self] _ in
            // Simply update Firebase.
            // The listener in startSession will trigger handleGlobalSessionEnd() for everyone.
            self?.firebase.endSession()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(endAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func handleGlobalSessionEnd() {
        // 1. Stop local audio engine & mic
        self.stopRecording()
        
        // 2. Remove any transient UI elements
        self.removeListeningBubble()
        
        // 3. Navigate to Summary Screen
        let storyboard = UIStoryboard(name: "Group-Join", bundle: nil)
        if let summaryVC = storyboard.instantiateViewController(withIdentifier: "GroupJoinSummaryViewController") as? GroupJoinSummaryViewController {
            
            // Pass the final transcript data
            summaryVC.transcriptMessages = self.messages
            summaryVC.conversationTitle = self.sessionTitle
            
            let nav = UINavigationController(rootViewController: summaryVC)
            nav.modalPresentationStyle = .pageSheet
            self.present(nav, animated: true)
        }
        
        // 4. Detach Firebase listeners
        firebase.stop()
    }
    
    // MARK: - Helpers
    private func updateMicButtonVisuals(isActive: Bool) {
        let imageName = isActive ? "mic.fill" : "mic.slash.fill"
        let tintColor = isActive ? UIColor.systemRed : UIColor.label
        GroupJoinMicButton.setImage(UIImage(systemName: imageName), for: .normal)
        GroupJoinMicButton.tintColor = tintColor
    }
    
    private func reloadDataAndScroll() {
        GroupJoinCollectionView.reloadData()
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let lastItem = IndexPath(item: messages.count - 1, section: 0)
        GroupJoinCollectionView.scrollToItem(at: lastItem, at: .bottom, animated: true)
    }
    
    // MARK: - DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupJoinIncomingCell", for: indexPath) as! GroupJoinIncomingCell
            cell.configure(with: message)
            cell.onLabelTapped = { [weak self] in self?.showRenameAlert() }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupJoinOutgoingCell", for: indexPath) as! GroupJoinOutgoingCell
            cell.configure(with: message)
            return cell
        }
    }
    
    func showRenameAlert() {
        let alert = UIAlertController(title: "Rename Speaker", message: "Enter name:", preferredStyle: .alert)
        alert.addTextField { $0.text = self.otherPersonName }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                self.otherPersonName = name
                for i in 0..<self.messages.count where self.messages[i].isIncoming {
                    self.messages[i].sender = name
                }
                self.GroupJoinCollectionView.reloadData()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
}
