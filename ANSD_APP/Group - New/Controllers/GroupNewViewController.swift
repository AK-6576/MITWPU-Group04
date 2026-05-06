//
//  GroupNewViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 18/03/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import Combine
import FoundationModels
import FirebaseAuth
import FirebaseDatabase

class GroupNewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    // MARK: - Dependencies
    private let firebase = FirebaseManager.shared
    private let cleanupManager = TextCleanupManager()
    private let model = SystemLanguageModel.default
    
    // MARK: - State
    private var speechRecognizer = SFSpeechRecognizer(locale: LanguageManager.shared.currentLocale)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var isRecording = false
    var isPaused = false
    var isHost = true
    var isRestarting = false
    var currentSessionID: String = ""
    var roomCodeShown = false
    
    var messages: [GroupNewChatMessage] = []
    var cleanedMessageIndices = Set<Int>()
    var consumedTranscriptOffset = 0
    
    // MARK: - Silence Detection
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.5
    
    // MARK: - User Info
    var currentUserID: String {
        let rawID = Auth.auth().currentUser?.uid ?? UIDevice.current.identifierForVendor?.uuidString ?? "UnknownUser"
        return rawID.components(separatedBy: CharacterSet(charactersIn: ".#$[]")).joined(separator: "_")
    }
    
    var myName: String {
        UserDefaults.standard.string(forKey: "user_first_name") ?? UIDevice.current.name
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSpeechPermissions()
        setupAudioSession()
        
        if currentSessionID.isEmpty {
            self.currentSessionID = String(Int.random(in: 1000...9999))
        }
        self.title = "Room: \(currentSessionID)"
        
        startSession()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: .languageDidChange, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showRoomCodeAlert()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isRecording && !isPaused {
            startRecording()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRecording()
        NotificationCenter.default.removeObserver(self, name: .languageDidChange, object: nil)
    }
    
    @objc private func handleLanguageChange() {
        speechRecognizer = SFSpeechRecognizer(locale: LanguageManager.shared.currentLocale)
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
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
            print("[GroupVC] Audio Session Error: \(error)")
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
    
    // MARK: - Speech Recognition
    
    private func startRecording() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        consumedTranscriptOffset = 0
        addListeningBubble()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            updateMicButtonVisuals(isActive: true)
        } catch {
            print("[GroupVC] Engine Start Error: \(error)")
            stopRecording()
        }
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] (result, error) in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let result = result {
                    let fullString = result.bestTranscription.formattedString
                    
                    // Safety check for transcript reset
                    if self.consumedTranscriptOffset > fullString.count {
                        self.consumedTranscriptOffset = 0
                    }
                    
                    let startIndex = fullString.index(fullString.startIndex, offsetBy: self.consumedTranscriptOffset)
                    let newContent = String(fullString[startIndex...])
                    self.consumedTranscriptOffset = fullString.count
                    
                    guard !newContent.isEmpty else { return }
                    
                    self.resetSilenceTimer()
                    self.handlePartialTranscript(newContent)
                }
                
                if let error = error {
                    if !self.isRestarting {
                        print("[GroupVC] Speech Error: \(error)")
                        self.stopRecording()
                    }
                    self.isRestarting = false
                }
            }
        }
    }
    
    private func handlePartialTranscript(_ newContent: String) {
        if let lastIndex = messages.lastIndex(where: { !$0.isIncoming }) {
            let currentText = messages[lastIndex].text
            let isPlaceholder = (currentText == "Listening..." || currentText == "...")
            let baseText = isPlaceholder ? "" : currentText
            let combinedText = baseText + newContent
            
            if combinedText.count > 240 {
                splitBubble(combinedText, at: lastIndex)
            } else {
                messages[lastIndex].text = combinedText
                collectionView.reloadItems(at: [IndexPath(item: lastIndex, section: 0)])
                scrollToBottom()
            }
        }
    }
    
    private func splitBubble(_ text: String, at index: Int) {
        let boundaries = [". ", "? ", "! "]
        var splitIndex: String.Index?
        
        let searchRange = text.startIndex..<text.index(text.startIndex, offsetBy: 240)
        for boundary in boundaries {
            if let range = text.range(of: boundary, options: .backwards, range: searchRange) {
                if splitIndex == nil || range.lowerBound > splitIndex! {
                    splitIndex = range.lowerBound
                }
            }
        }
        
        if let idx = splitIndex {
            let endOfSentence = text.index(idx, offsetBy: 1)
            let firstPart = String(text[...endOfSentence]).trimmingCharacters(in: .whitespacesAndNewlines)
            let secondPart = String(text[text.index(after: endOfSentence)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            messages[index].text = firstPart
            collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            triggerCleanup(for: firstPart, at: index)
            
            let newMsg = GroupNewChatMessage(text: secondPart.isEmpty ? "..." : secondPart, isIncoming: false, sender: myName, senderID: currentUserID)
            messages.append(newMsg)
            reloadDataAndScroll()
        } else {
            messages[index].text = text
            collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        }
    }
    
    // MARK: - Cleanup & Silence
    
    private func triggerCleanup(for text: String, at index: Int) {
        guard !cleanedMessageIndices.contains(index) else { return }
        cleanedMessageIndices.insert(index)
        
        cleanupManager.scheduleCleanup(text: text, at: index) { [weak self] idx, cleaned in
            guard let self = self else { return }
            Task { @MainActor in
                if idx < self.messages.count {
                    self.messages[idx].text = cleaned
                    self.collectionView.reloadItems(at: [IndexPath(item: idx, section: 0)])
                    self.firebase.send(text: cleaned, sender: self.myName, senderID: self.currentUserID)
                }
            }
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.handleSilenceDetected() }
        }
    }
    
    private func handleSilenceDetected() {
        if let lastIndex = messages.lastIndex(where: { !$0.isIncoming }) {
            let text = messages[lastIndex].text
            if text != "Listening..." && text != "..." && !text.isEmpty {
                triggerCleanup(for: text, at: lastIndex)
            }
        }
        if isRecording {
            restartRecordingCycle()
        }
    }
    
    private func restartRecordingCycle() {
        isRestarting = true
        stopRecording()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.isRestarting { self.startRecording() }
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        removeListeningBubble()
        updateMicButtonVisuals(isActive: false)
    }
    
    // MARK: - Firebase & Session
    
    private func startSession() {
        firebase.registerRoom(code: currentSessionID, hostUID: currentUserID)
        firebase.setupSession(hostUID: currentUserID, conversationID: currentSessionID, isHost: isHost)
        
        firebase.observeSessionStatus { [weak self] status in
            if status == "ended" { self?.handleGlobalSessionEnd() }
        }
        
        firebase.observeMessages { [weak self] data in
            guard let self = self else { return }
            if let text = data["text"] as? String,
               let sender = data["sender"] as? String,
               let senderID = data["senderID"] as? String,
               senderID != self.currentUserID {
                
                self.removeListeningBubble()
                let msg = GroupNewChatMessage(text: text, isIncoming: true, sender: sender, senderID: senderID)
                self.messages.append(msg)
                self.reloadDataAndScroll()
                if self.isRecording { self.addListeningBubble() }
            }
        }
    }
    
    @IBAction func endButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "End Session?", message: "This will end the meeting for everyone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "End", style: .destructive) { _ in self.firebase.endSession() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func handleGlobalSessionEnd() {
        stopRecording()
        let storyboard = UIStoryboard(name: "Group-New", bundle: nil)
        if let summaryVC = storyboard.instantiateViewController(withIdentifier: "GroupNewSummaryViewController") as? GroupNewSummaryViewController {
            summaryVC.transcriptMessages = self.messages
            summaryVC.conversationTitle = "Room \(self.currentSessionID)"
            let nav = UINavigationController(rootViewController: summaryVC)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        }
        firebase.stop()
    }
    
    // MARK: - Actions
    
    @IBAction func micButtonTapped(_ sender: UIButton) {
        isRecording ? stopRecording() : startRecording()
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        isPaused.toggle()
        let icon = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setImage(UIImage(systemName: icon), for: .normal)
        isPaused ? stopRecording() : startRecording()
    }
    
    @IBAction func addPersonTapped(_ sender: UIBarButtonItem) {
        showRoomCodeAlert()
    }
    
    private func showRoomCodeAlert() {
        let alert = UIAlertController(title: "Room Code", message: "Share code: \(currentSessionID)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in UIPasteboard.general.string = self.currentSessionID })
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateMicButtonVisuals(isActive: Bool) {
        let icon = isActive ? "mic.fill" : "mic.slash.fill"
        micButton.setImage(UIImage(systemName: icon), for: .normal)
    }
    
    // MARK: - Bubble Logic
    
    private func addListeningBubble() {
        if messages.last?.text == "Listening..." { return }
        let msg = GroupNewChatMessage(text: "Listening...", isIncoming: false, sender: myName, senderID: currentUserID)
        messages.append(msg)
        reloadDataAndScroll()
    }
    
    private func removeListeningBubble() {
        messages.removeAll { ($0.text == "Listening..." || $0.text == "...") && !$0.isIncoming }
        reloadDataAndScroll()
    }
    
    private func reloadDataAndScroll() {
        collectionView.reloadData()
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let last = IndexPath(item: messages.count - 1, section: 0)
        collectionView.scrollToItem(at: last, at: .bottom, animated: true)
    }
    
    // MARK: - CollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let msg = messages[indexPath.row]
        if msg.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupNewIncomingCell", for: indexPath) as! GroupNewIncomingCell
            cell.configure(with: msg)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupNewOutgoingCell", for: indexPath) as! GroupNewOutgoingCell
            cell.configure(with: msg)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - 32, height: 60)
    }
}
