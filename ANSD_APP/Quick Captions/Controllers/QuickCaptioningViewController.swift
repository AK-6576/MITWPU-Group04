//
//  QuickCaptioningViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import Combine
import CoreLocation
import MapKit
import FoundationModels

let MAX_BUBBLE_CHAR_LIMIT = 120

class QuickCaptioningViewController: UIViewController,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    CLLocationManagerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var endButton: UIBarButtonItem!

    var messages: [QuickCaptionsChat] = []
    
    // MARK: - Buffering & Logic State
    private var transcriptBuffer: String = ""
    
    let locationManager = CLLocationManager()
    var currentLocationString: String = "Location Unknown"
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private let diarizer = AudioDiarizer()
    private var diarizerCancellables = Set<AnyCancellable>()
    private var currentSpeakerID: Int?
    private let cleanupManager = TextCleanupManager()

    var isRecording = false
    var currentMessageIndex: Int?
    
    var consumedTranscriptOffset = 0
    var hasEnrolled = false

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupPermission()
        setupAudioSession()
        bindDiarizer()
        setupLocation()
        
        checkCalibrationStatus()
    }
            
            // MARK: - Voice Profile Check
    private func checkCalibrationStatus() {
        if let savedProfile = VoiceProfileManager.shared.getVoiceProfile(byId: 0) {
            // Profile exists! Load it into the Diarizer memory
            diarizer.speakerProfiles[0] = savedProfile.embedding
            diarizer.speakerNames[0] = savedProfile.name
            hasEnrolled = true
            
            startSession()
        } else {
            // No profile exists. Trigger the Calibration Prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.promptForEnrollment()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupManager.cancelAllPendingTasks()
        stopRecording()
    }
    
    // MARK: - Location Services
    
    func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        
        if let request = MKReverseGeocodingRequest(location: loc) {
            request.getMapItems { [weak self] mapItems, error in
                guard let self = self else { return }
                if let place = mapItems?.first?.placemark {
                    let city = place.locality ?? ""
                    let country = place.country ?? ""
                    if !city.isEmpty {
                        self.currentLocationString = "\(city), \(country)"
                    }
                }
            }
        }
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Voice Enrollment
    
    private func promptForEnrollment() {
        let longerPhrase = """
        I am speaking to calibrate my voice profile. 
        This will ensure accurate identification during the session.
        """
        let alert = UIAlertController(title: "Voice Calibration", message: "Tap 'Start Recording' and read clearly:\n\n\"\(longerPhrase)\"", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Start Recording", style: .default) { [weak self] _ in self?.runEnrollmentRecording() })
        alert.addAction(UIAlertAction(title: "Skip", style: .cancel) { [weak self] _ in self?.hasEnrolled = true; self?.startSession() })
        present(alert, animated: true)
    }
    
    private func runEnrollmentRecording() {
        diarizer.enrollUser { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async { self.stopRecording(); self.promptForUserName() }
        }
        try? startAudioEngine()
    }
    
    private func promptForUserName() {
        let alert = UIAlertController(title: "Voice Saved", message: "What is your name?", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Your Name"; tf.autocapitalizationType = .words }
        alert.addAction(UIAlertAction(title: "Save & Start", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let name = alert.textFields?.first?.text ?? "Me"
            
            // 1. Update the Diarizer locally
            self.diarizer.setUserName(name)
            
            // 2. Extract the mathematical vector and Save Permanently to SwiftData!
            if let userVector = self.diarizer.speakerProfiles[0] {
                VoiceProfileManager.shared.saveVoiceProfile(id: 0, name: name, embedding: userVector)
            }
            
            self.hasEnrolled = true
            self.startSession()
        })
        present(alert, animated: true)
    }

    // MARK: - Session Management
    
    private func startSession() {
        if isRecording { return }
        consumedTranscriptOffset = 0
        transcriptBuffer = ""
        
        startSpeechRecognition()
        try? startAudioEngine()
        appendNewBubble(text: "Listening...", isBlue: false, name: "System", id: nil)
        isRecording = true
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }

    // MARK: - Speech Recognition
    
    private func startSpeechRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self, let result = result else { return }
            self.handleSpeechTranscript(fullText: result.bestTranscription.formattedString, isFinal: result.isFinal)
        }
    }

    // MARK: - Transcript Handling (FIXED DUPLICATION)
    
    private func handleSpeechTranscript(fullText: String, isFinal: Bool) {
        // SAFETY CHECK: If offset > fullText, a correction happened (backspace).
        // Return immediately to prevent reading old text as new text (Duplication Fix).
        if consumedTranscriptOffset > fullText.count {
            return
        }
        
        let startIndex = fullText.index(fullText.startIndex, offsetBy: consumedTranscriptOffset)
        let newContent = String(fullText[startIndex...])
        
        guard !newContent.isEmpty else { return }
        
        // Add to Buffer
        transcriptBuffer += newContent
        consumedTranscriptOffset = fullText.count
        
        // Process Buffer
        processBuffer()
        
        if isFinal {
            // Ensure everything is flushed
            if !transcriptBuffer.isEmpty { processBuffer() }
            
            // Clean the last active bubble since the sentence is done
            if !messages.isEmpty {
                finalizeBubble(at: messages.count - 1)
            }
            
            transcriptBuffer = ""
            // NOTE: Do NOT reset consumedTranscriptOffset here unless we restart the request object.
        }
    }
    
    private func processBuffer() {
        guard !transcriptBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let speakerID = currentSpeakerID else { return }
        
        let textToFlush = transcriptBuffer
        
        // Check LAST message
        if let lastMsg = messages.last,
           let lastID = lastMsg.speakerID,
           lastID == speakerID {
            
            // SAME SPEAKER: Append
            updateLastBubble(with: textToFlush)
            
        } else {
            // DIFFERENT SPEAKER: Split
            
            // Seal previous bubble
            if !messages.isEmpty {
                finalizeBubble(at: messages.count - 1)
            }
            
            // Create new bubble
            flushBufferToNewBubble(text: textToFlush, speakerID: speakerID)
        }
        
        // Clear buffer strictly after processing
        transcriptBuffer = ""
    }
    
    private func flushBufferToNewBubble(text: String, speakerID: Int) {
        let isBlue = (speakerID == 0) // ID 0 is enrolled user
        
        var name = "..."
        if isBlue {
            name = diarizer.speakerNames[0] ?? "Me"
        } else {
            name = diarizer.speakerNames[speakerID] ?? "Speaker \(speakerID)"
        }
        
        DispatchQueue.main.async {
            self.appendNewBubble(text: text, isBlue: isBlue, name: name, id: speakerID)
        }
    }
    
    private func updateLastBubble(with text: String) {
        DispatchQueue.main.async {
            guard !self.messages.isEmpty else { return }
            let lastIndex = self.messages.count - 1
            
            let currentText = self.messages[lastIndex].text
            let newText = currentText + text
            
            self.updateBubbleUI(at: lastIndex, text: newText)
        }
    }
    
    // MARK: - Cleanup & UI Updates
    
    private func finalizeBubble(at index: Int) {
        let text = messages[index].text
        guard messages[index].sender != "Listening...", messages[index].sender != "System" else { return }
        
        cleanupManager.scheduleCleanup(text: text, at: index) { [weak self] idx, cleaned in
            self?.updateBubbleUI(at: idx, text: cleaned)
        }
    }
    
    private func updateBubbleUI(at index: Int, text: String) {
        DispatchQueue.main.async {
            guard index < self.messages.count else { return }
            
            if self.messages[index].text != text {
                self.messages[index].text = text
                UIView.performWithoutAnimation {
                    self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                }
                if index == self.messages.count - 1 {
                    self.scrollToBottom()
                }
            }
        }
    }
    
    private func appendNewBubble(text: String, isBlue: Bool, name: String, id: Int?) {
        if let last = messages.last, (last.sender == "Listening..." || last.sender == "System") { messages.removeLast() }
        
        var newMessage = QuickCaptionsChat(sender: name, text: text, isIncoming: !isBlue)
        newMessage.speakerID = id
        
        messages.append(newMessage)
        currentMessageIndex = messages.count - 1
        if let sid = id { currentSpeakerID = sid }
        collectionView.reloadData()
        scrollToBottom()
    }

    // MARK: - Diarizer Binding
    
    private func bindDiarizer() {
        diarizer.$currentSpeakerID.receive(on: DispatchQueue.main).sink { [weak self] id in
            guard let self = self else { return }
            self.currentSpeakerID = id
            
            // Trigger buffer processing immediately
            if id != nil {
                self.processBuffer()
            }
            
            // Check for name updates (renames)
            if let validID = id, !self.messages.isEmpty {
                let lastIdx = self.messages.count - 1
                if self.messages[lastIdx].speakerID == validID {
                    var newName = "..."
                    if validID == 0 { newName = self.diarizer.speakerNames[0] ?? "Me" }
                    else { newName = self.diarizer.speakerNames[validID] ?? "Speaker \(validID)" }
                    
                    if self.messages[lastIdx].sender != newName {
                        self.messages[lastIdx].sender = newName
                        UIView.performWithoutAnimation { self.collectionView.reloadItems(at: [IndexPath(item: lastIdx, section: 0)]) }
                    }
                }
            }
        }.store(in: &diarizerCancellables)
    }

    // MARK: - Audio Configuration
    
    private func startAudioEngine() throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            if self.isRecording { self.recognitionRequest?.append(buffer) }
            self.diarizer.handleAudio(buffer: buffer, targetFormat: AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - UI Setup
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout { layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize }
        collectionView.keyboardDismissMode = .interactive
    }
    
    // MARK: - End Session & Summary
    
    @IBAction func didTapStopButton(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "End Session?", message: "Are you sure?", preferredStyle: .alert)
        
        let endAction = UIAlertAction(title: "End Session", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            if !self.messages.isEmpty {
                self.finalizeBubble(at: self.messages.count - 1)
            }
            
            self.stopRecording()
            
            let storyboard = UIStoryboard(name: "Quick Captions", bundle: nil)
            
            if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
               let summaryVC = summaryNav.topViewController as? SummaryViewController {
                
                let transcript = self.messages.toTranscriptString()
                
                summaryVC.rawTranscriptText = transcript
                summaryVC.rawMessages = self.messages
                summaryVC.conversationTitle = "Conversation 1"
                
                let now = Date()
                let dateFormatter = DateFormatter()
                
                dateFormatter.dateFormat = "MMMM"
                let month = dateFormatter.string(from: now)
                
                let calendar = Calendar.current
                let day = calendar.component(.day, from: now)
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .ordinal
                let dayWithSuffix = numberFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
                
                summaryVC.dateString = "\(month) \(dayWithSuffix)"
                
                dateFormatter.dateFormat = "h:mm a"
                summaryVC.timeString = dateFormatter.string(from: now)
                
                summaryVC.locationString = self.currentLocationString
                
                var participants: [QuickCaptionsParticipantData] = []
                let uniqueSenders = Set(self.messages.map { $0.sender }).sorted()
                
                for name in uniqueSenders {
                    if name != "Listening..." && name != "..." && name != "System" {
                        participants.append(QuickCaptionsParticipantData(name: name, summary: "Waiting for analysis..."))
                    }
                }
                
                summaryVC.participantsData = participants
                
                summaryNav.modalPresentationStyle = .pageSheet
                self.present(summaryNav, animated: true, completion: nil)
            }
        }
        
        actionSheet.addAction(endAction)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(actionSheet, animated: true)
    }
    
    // MARK: - CollectionView Delegate & DataSource
    
    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        collectionView.scrollToItem(at: IndexPath(item: messages.count - 1, section: 0), at: .bottom, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return messages.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let msg = messages[indexPath.row]
        if msg.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QCIncomingCell", for: indexPath) as! QuickCaptionsIncomingCell
            cell.messageLabel.text = msg.text
            cell.nameLabel.text = msg.sender
            cell.onLabelTapped = { [weak self] in self?.showRenameAlert(for: indexPath.row) }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QCOutgoingCell", for: indexPath) as! QuickCaptionsOutgoingCell
            cell.QCmessageLabel.text = msg.text
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
    // MARK: - Permissions
    
    private func setupPermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { allowed in }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in }
        }
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    // MARK: - Rename & Time Machine
    
    private func showRenameAlert(for index: Int) {
        let msg = messages[index]
        let currentName = msg.sender
        let alert = UIAlertController(title: "Rename \(currentName)", message: "This will update past and future bubbles.", preferredStyle: .alert)
        alert.addTextField { tf in tf.text = currentName; tf.autocapitalizationType = .words }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            if let bubbleSpeakerID = msg.speakerID {
                self.diarizer.speakerNames[bubbleSpeakerID] = newName
            } else {
                if let key = self.diarizer.speakerNames.first(where: { $0.value == currentName })?.key {
                    self.diarizer.speakerNames[key] = newName
                }
            }

            for i in 0..<self.messages.count {
                if self.messages[i].sender == currentName {
                    self.messages[i].sender = newName
                }
                if let sid = self.messages[i].speakerID,
                   let registeredName = self.diarizer.speakerNames[sid],
                   registeredName == newName {
                    self.messages[i].sender = newName
                }
            }
            
            self.collectionView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension Array where Element == QuickCaptionsChat {
    func toTranscriptString() -> String {
        return self.map { "\($0.sender): \($0.text)" }.joined(separator: "\n\n")
    }
}
