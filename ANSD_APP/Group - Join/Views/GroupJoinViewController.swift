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

class GroupJoinViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSpeechRecognizerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var GroupJoinCollectionView: UICollectionView!
    @IBOutlet weak var GroupJoinPauseButton: UIButton!
    @IBOutlet weak var GroupJoinMicButton: UIButton!
    @IBOutlet weak var GroupJoinEndButton: UIButton!
    
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
    var isHost = false // Joiners are NOT hosts
    var isRestarting = false // Logic to prevent auto-mute
    
    var messages: [GroupJoinChatMessage] = []
    var currentSessionID: String = "" // Passed from previous screen
    
    // Identity
    let currentUserID = UIDevice.current.identifierForVendor?.uuidString ?? "GuestUser"
    let myName = UIDevice.current.name // Device Name
    
    var otherPersonName = "Host" // Default name for others

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSpeechPermissions()
        setupAudioSession()
        
        // Title
        self.title = "Session: \(currentSessionID)"
        
        // Start Firebase connection immediately using passed ID
        if !currentSessionID.isEmpty {
            startSession()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Auto-start mic
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
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
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
    
    // MARK: - Speech Logic (Monolithic)
    private func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
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
                let rawText = result.bestTranscription.formattedString
                self.updateListeningBubble(with: rawText)
                
                self.cleanupManager.scheduleCleanup(text: rawText, at: 0) { _, cleanedText in
                    // Send to Firebase
                    self.firebase.send(text: cleanedText, sender: self.myName, senderID: self.currentUserID)
                    
                    if self.isRecording {
                        self.restartRecordingCycle()
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
        messages.removeAll { $0.text == "Listening..." && !$0.isIncoming }
        reloadDataAndScroll()
    }
    
    // MARK: - Firebase Logic
    private func startSession() {
        // isHost = false because we are joining
        firebase.setupSession(id: currentSessionID, isHost: isHost)
        
        firebase.observeMessages { [weak self] data in
            guard let self = self else { return }
            
            if let text = data["text"] as? String,
               let sender = data["sender"] as? String,
               let senderID = data["senderID"] as? String {
                
                // Confirm own message sent
                if senderID == self.currentUserID {
                    self.removeListeningBubble()
                    if self.isRecording { self.addListeningBubble() }
                }
                
                let isIncoming = senderID != self.currentUserID
                let msg = GroupJoinChatMessage(text: text, isIncoming: isIncoming, sender: sender, senderID: senderID)
                self.messages.append(msg)
                self.reloadDataAndScroll()
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
        let actionSheet = UIAlertController(title: "Leave Session?", message: "Do you want to leave and see summary?", preferredStyle: .actionSheet)
        
        let endAction = UIAlertAction(title: "Leave & Summarize", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.stopRecording()
            
            let storyboard = UIStoryboard(name: "Group-Join", bundle: nil)
            if let summaryVC = storyboard.instantiateViewController(withIdentifier: "GroupJoinSummaryViewController") as? GroupJoinSummaryViewController {
                
                // Pass Data
                summaryVC.transcriptMessages = self.messages
                summaryVC.conversationTitle = "Session \(self.currentSessionID)"
                
                let nav = UINavigationController(rootViewController: summaryVC)
                nav.modalPresentationStyle = .pageSheet
                self.present(nav, animated: true)
            }
        }
        
        actionSheet.addAction(endAction)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = sender
        }
        present(actionSheet, animated: true)
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
}
