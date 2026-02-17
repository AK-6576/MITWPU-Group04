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
    var isRestarting = false // FIX: Prevents auto-mute logic
    var roomCodeShown = false // Controls pop-up frequency
    
    var otherPersonName = "Guest"
    var messages: [GroupNewChatMessage] = []
    var currentSessionID: String = ""
    
    // Identity
    let currentUserID = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownUser"
    let myName = UIDevice.current.name // This ensures Device Name appears in Summary
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSpeechPermissions()
        setupAudioSession()
        
        // Generate Code if Host
        if currentSessionID.isEmpty {
            self.currentSessionID = "\(Int.random(in: 1000...9999))"
        }
        
        startSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 1. Auto-Start Recording
        if !isRecording {
            startRecording()
        }
        
        // 2. Room Code Pop-up (Only once)
        if !roomCodeShown {
            showRoomCodePopup()
            roomCodeShown = true
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
        // Safety Clean
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
                
                // Cleanup Trigger
                self.cleanupManager.scheduleCleanup(text: rawText, at: 0) { _, cleanedText in
                    self.firebase.send(text: cleanedText, sender: self.myName, senderID: self.currentUserID)
                    
                    if self.isRecording {
                        self.restartRecordingCycle()
                    }
                }
            }
            
            if let error = error {
                // FIX: Check 'isRestarting'. If true, this error is expected (cancellation), so DO NOT STOP.
                if !self.isRestarting {
                    print("Speech Error: \(error)")
                    self.stopRecording()
                } else {
                    // Reset flag for next cycle
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
        // FIX: Set flag to ignore the cancellation error from the old task
        isRestarting = true
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        
        removeListeningBubble()
        startRecording() // Start fresh immediately
    }
    
    // MARK: - Bubble Logic
    private func addListeningBubble() {
        if let last = messages.last, last.text == "Listening..." && !last.isIncoming { return }
        let listeningMsg = GroupNewChatMessage(text: "Listening...", isIncoming: false, sender: myName, senderID: currentUserID)
        messages.append(listeningMsg)
        reloadDataAndScroll()
    }
    
    private func updateListeningBubble(with text: String) {
        if let index = messages.lastIndex(where: { !$0.isIncoming }) {
            messages[index].text = text
            let indexPath = IndexPath(item: index, section: 0)
            UIView.performWithoutAnimation {
                self.collectionView.reloadItems(at: [indexPath])
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
        firebase.setupSession(id: currentSessionID, isHost: isHost)
        firebase.observeMessages { [weak self] data in
            guard let self = self else { return }
            
            if let text = data["text"] as? String,
               let sender = data["sender"] as? String,
               let senderID = data["senderID"] as? String {
                
                if senderID == self.currentUserID {
                    self.removeListeningBubble()
                    if self.isRecording { self.addListeningBubble() }
                }
                
                let isIncoming = senderID != self.currentUserID
                let msg = GroupNewChatMessage(text: text, isIncoming: isIncoming, sender: sender, senderID: senderID)
                self.messages.append(msg)
                self.reloadDataAndScroll()
            }
        }
    }
    
    // MARK: - Pop-ups & Actions
    
    func showRoomCodePopup() {
        let alert = UIAlertController(title: "Session Started", message: "Room Code: \(currentSessionID)", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Copy Code", style: .default) { _ in
            UIPasteboard.general.string = self.currentSessionID
        })
        
        alert.addAction(UIAlertAction(title: "Share", style: .default) { _ in
            self.shareRoomInvitation()
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func micButtonTapped(_ sender: UIButton) {
        isRecording ? stopRecording() : startRecording()
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        isPaused.toggle()
        let iconName = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setImage(UIImage(systemName: iconName), for: .normal)
        isPaused ? stopRecording() : startRecording()
    }
    
    @IBAction func endButtonTapped(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "End Session?", message: "Are you sure?", preferredStyle: .actionSheet)
        
        let endAction = UIAlertAction(title: "End Session", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.stopRecording()
            self.firebase.stop()
            
            let storyboard = UIStoryboard(name: "Group-New", bundle: nil)
            if let summaryVC = storyboard.instantiateViewController(withIdentifier: "GroupNewSummaryViewController") as? GroupNewSummaryViewController {
                summaryVC.transcriptMessages = self.messages
                summaryVC.conversationTitle = "Session \(self.currentSessionID)"
                
                let nav = UINavigationController(rootViewController: summaryVC)
                nav.modalPresentationStyle = .pageSheet
                self.present(nav, animated: true)
            }
        }
        
        actionSheet.addAction(endAction)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    @IBAction func addPersonTapped(_ sender: Any) {
        showRoomCodePopup()
    }
    
    func shareRoomInvitation() {
        let invite = "Join session: \(currentSessionID)"
        let activityVC = UIActivityViewController(activityItems: [invite], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    // MARK: - Helpers
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
    
    // MARK: - DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupNewIncomingCell", for: indexPath) as! GroupNewIncomingCell
            cell.configure(with: message)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupNewOutgoingCell", for: indexPath) as! GroupNewOutgoingCell
            cell.configure(with: message)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
}
