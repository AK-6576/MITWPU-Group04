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
import FirebaseAuth

let MAX_BUBBLE_CHAR_LIMIT = 240

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
    private var holdTimer: Timer?
    
    let locationManager = CLLocationManager()
    var currentLocationString: String = "Location Unknown"
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer = SFSpeechRecognizer(locale: LanguageManager.shared.currentLocale)

    private let diarizer = AudioDiarizer()
    private var diarizerCancellables = Set<AnyCancellable>()
    private var currentSpeakerID: Int?
    private let cleanupManager = TextCleanupManager()

    var isRecording = false
    var currentMessageIndex: Int?
    
    var consumedTranscriptOffset = 0
    var hasEnrolled = false
    private var forceNewBubble = false
    private var cleanupIDs: [UUID] = []

    // MARK: - Apple Intelligence — Semantic Diarization
    /// SemanticDiarizationAdvisor instance (iOS 18.1+ only; nil on older OS).
    private var semanticAdvisor: AnyObject? = nil
    /// Set to true by the advisor's async prediction; consumed in processBuffer.
    private var semanticSpeakerChangeExpected = false

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupPermission()
        setupAudioSession()
        bindDiarizer()
        setupLocation()
        
        checkCalibrationStatus()

        // Boot Apple Intelligence semantic layer (graceful no-op on < iOS 18.1).
        if #available(iOS 18.1, *) {
            semanticAdvisor = SemanticDiarizationAdvisor()
            print("🧠 [SemanticAdvisor] Apple Intelligence diarization layer active")
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: .languageDidChange, object: nil)
    }
    
    @objc private func handleLanguageChange() {
        speechRecognizer = SFSpeechRecognizer(locale: LanguageManager.shared.currentLocale)
    }
            
    // MARK: - Voice Profile Check
    private func checkCalibrationStatus() {
        if let uid = Auth.auth().currentUser?.uid, let savedProfile = VoiceProfileManager.shared.getVoiceProfile(byUID: uid) {
            
            // ⭐️ Uses the new helper to lock your absolute anchor into the Diarizer
            diarizer.setPreEnrolledProfile(vector: savedProfile.embedding, name: savedProfile.name)
            
            hasEnrolled = true
            startSession()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.promptForEnrollment()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupManager.cancelAllPendingTasks()
        stopRecording()
        NotificationCenter.default.removeObserver(self, name: .languageDidChange, object: nil)
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
                if let place = mapItems?.first {
                    let city = place.addressRepresentations?.cityName ?? ""
                    let country = place.addressRepresentations?.regionName ?? ""
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
        // AGC ON during enrollment: normalises the user's voice level so the
        // VL1004 embedding is captured at a consistent amplitude.
        try? startAudioEngine(forEnrollment: true)
    }
    
    private func promptForUserName() {
        let alert = UIAlertController(title: "Voice Saved", message: "What is your name?", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Your Name"; tf.autocapitalizationType = .words }
        alert.addAction(UIAlertAction(title: "Save & Start", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let name = alert.textFields?.first?.text ?? "Me"
            
            self.diarizer.setUserName(name)
            
            if let userVector = self.diarizer.speakerProfiles[0], let uid = Auth.auth().currentUser?.uid {
                VoiceProfileManager.shared.saveVoiceProfile(ownerUID: uid, name: name, embedding: userVector)
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
        forceNewBubble = false
        
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

    // MARK: - Transcript Handling
    
    private func handleSpeechTranscript(fullText: String, isFinal: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.consumedTranscriptOffset > fullText.count {
                return
            }
            
            let startIndex = fullText.index(fullText.startIndex, offsetBy: self.consumedTranscriptOffset)
            let newContent = String(fullText[startIndex...])
            
            guard !newContent.isEmpty else { return }
            
            self.transcriptBuffer += newContent
            self.consumedTranscriptOffset = fullText.count
            
            self.holdTimer?.invalidate()
            self.holdTimer = nil
            
            if isFinal {
                if !self.transcriptBuffer.isEmpty { self.processBuffer() }
                if !self.messages.isEmpty {
                    self.finalizeBubble(at: self.messages.count - 1)
                    self.forceNewBubble = true
                    self.showIdentifyingPlaceholder()
                }
                self.transcriptBuffer = ""
            } else {
                self.holdTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { [weak self] _ in
                    self?.holdTimer = nil
                    self?.processBuffer()

                    if let messages = self?.messages, !messages.isEmpty {
                        self?.finalizeBubble(at: messages.count - 1)
                        self?.forceNewBubble = true
                        self?.showIdentifyingPlaceholder()
                    }
                }
            }
        }
    }
    
    private func processBuffer() {
        guard !transcriptBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Use -1 as a sentinel for "diarizer hasn't fired yet".
        // Text streams into a neutral pending bubble immediately so the user
        // sees captions right away; handleDiarizationRefinement corrects the
        // speaker/colour in-place once the first diarizer result arrives.
        let speakerID = currentSpeakerID ?? -1

        // Apple Intelligence semantic override: if the on-device LLM predicted
        // a speaker change since the last bubble, honour it.
        // (Skip during pending phase — speaker is unknown anyway.)
        if speakerID != -1 && semanticSpeakerChangeExpected {
            semanticSpeakerChangeExpected = false
            forceNewBubble = true
        }

        let textToFlush = transcriptBuffer

        if let lastMsg = messages.last,
           let lastID = lastMsg.speakerID,
           lastID == speakerID,
           !self.forceNewBubble {

            updateLastBubble(with: textToFlush)

        } else {
            self.forceNewBubble = false

            if !messages.isEmpty {
                finalizeBubble(at: messages.count - 1)
            }

            flushBufferToNewBubble(text: textToFlush, speakerID: speakerID)
        }

        transcriptBuffer = ""
    }
    
    // MARK: - Identifying Placeholder

    /// Appends a transient neutral bubble labelled "Identifying…" so the user
    /// knows the ML pipeline is processing — not frozen. Because its sender is
    /// "Listening...", appendNewBubble removes it automatically the moment real
    /// speech content arrives. Zero manual cleanup required.
    private func showIdentifyingPlaceholder() {
        appendNewBubble(text: "Identifying\u{2026}", isBlue: false,
                        name: "Listening...", id: nil)
    }

    private func flushBufferToNewBubble(text: String, speakerID: Int) {
        // speakerID == -1: cold-start pending state — diarizer hasn't returned yet.
        // Show a neutral grey bubble; handleDiarizationRefinement will correct it.
        if speakerID == -1 {
            self.appendNewBubble(text: text, isBlue: false, name: "Identifying…", id: -1)
            return
        }

        let isBlue = (speakerID == 0)
        var name = "..."
        if isBlue {
            name = diarizer.speakerNames[0] ?? "Me"
        } else {
            name = diarizer.speakerNames[speakerID] ?? "Speaker \(speakerID)"
        }
        self.appendNewBubble(text: text, isBlue: isBlue, name: name, id: speakerID)
    }
    
    private func updateLastBubble(with text: String) {
        DispatchQueue.main.async {
            guard !self.messages.isEmpty else { return }
            
            let activeIndex = self.messages.count - 1
            let currentText = self.messages[activeIndex].text
            
            // If the bubble is currently holding a placeholder, replace it entirely.
            // Otherwise, append the new text.
            let isPlaceholder = (currentText == "..." || currentText == "Identifying\u{2026}")
            let combinedText = isPlaceholder ? text : currentText + text
            
            // Only split if we exceed the 3-line limit (~240 chars)
            if combinedText.count > MAX_BUBBLE_CHAR_LIMIT {
                var splitIndex = combinedText.index(combinedText.startIndex, offsetBy: MAX_BUBBLE_CHAR_LIMIT)
                
                // Try to find the last sentence boundary before the limit
                let boundaries = [". ", "? ", "! ", ".\n", "?\n", "!\n"]
                var bestBoundaryRange: Range<String.Index>? = nil
                
                let searchRange = combinedText.startIndex..<splitIndex
                for boundary in boundaries {
                    if let range = combinedText.range(of: boundary, options: .backwards, range: searchRange) {
                        if bestBoundaryRange == nil || range.lowerBound > bestBoundaryRange!.lowerBound {
                            bestBoundaryRange = range
                        }
                    }
                }
                
                if let range = bestBoundaryRange {
                    let firstPart = String(combinedText[...range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let secondPart = String(combinedText[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    self.updateBubbleUI(at: activeIndex, text: firstPart)
                    self.finalizeBubble(at: activeIndex)
                    
                    if let speakerID = self.messages[activeIndex].speakerID {
                        self.flushBufferToNewBubble(text: secondPart.isEmpty ? "..." : secondPart, speakerID: speakerID)
                    }
                } else {
                    // No sentence boundary found, keep it together for now or split at space
                    if let spaceRange = combinedText.range(of: " ", options: .backwards, range: searchRange) {
                        let firstPart = String(combinedText[...spaceRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let secondPart = String(combinedText[spaceRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        self.updateBubbleUI(at: activeIndex, text: firstPart)
                        self.finalizeBubble(at: activeIndex)
                        
                        if let speakerID = self.messages[activeIndex].speakerID {
                            self.flushBufferToNewBubble(text: secondPart.isEmpty ? "..." : secondPart, speakerID: speakerID)
                        }
                    } else {
                        // Hard split as last resort
                        self.updateBubbleUI(at: activeIndex, text: combinedText)
                    }
                }
            } else {
                self.updateBubbleUI(at: activeIndex, text: combinedText)
            }
        }
    }
    
    // MARK: - Cleanup & UI Updates
    
    private func finalizeBubble(at index: Int) {
        guard index < messages.count, index < cleanupIDs.count else { return }
        let text = messages[index].text
        let speaker = messages[index].sender
        guard speaker != "Listening...", speaker != "System" else { return }

        self.updateBubbleUI(at: index, text: text)

        let targetID = cleanupIDs[index]

        cleanupManager.scheduleCleanup(text: text, at: index) { [weak self] _, cleaned in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let currentIndex = self.cleanupIDs.firstIndex(of: targetID) else { return }
                self.messages[currentIndex].text = cleaned
                UIView.performWithoutAnimation {
                    self.collectionView.reloadItems(at: [IndexPath(item: currentIndex, section: 0)])
                }
                self.scrollToBottom()
            }
        }

        // 🧠 Apple Intelligence: record this utterance and pre-compute whether
        // the NEXT utterance will be a speaker change.  The LLM runs during the
        // inter-utterance silence so the prediction is ready before the next
        // processBuffer() call.
        if #available(iOS 18.1, *),
           let advisor = semanticAdvisor as? SemanticDiarizationAdvisor {
            advisor.record(speaker: speaker, text: text)
            Task { [weak self] in
                let change = await advisor.predictSpeakerChange()
                if change {
                    await MainActor.run { self?.semanticSpeakerChangeExpected = true }
                }
            }
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
        if let last = messages.last, (last.sender == "Listening..." || last.sender == "System") {
            messages.removeLast()
            if !cleanupIDs.isEmpty { cleanupIDs.removeLast() }
        }

        let senderID = id != nil ? String(id!) : "system"
        var newMessage = QuickCaptionsChat(sender: name, senderID: senderID, text: text, isIncoming: !isBlue)
        newMessage.speakerID = id
        if let currentEvent = diarizer.segmentHistory.last {
            newMessage.eventId = currentEvent.id
            newMessage.timestamp = currentEvent.timestamp
        } else {
            newMessage.timestamp = Date()
        }

        messages.append(newMessage)
        cleanupIDs.append(UUID())
        currentMessageIndex = messages.count - 1
        if let sid = id {
            currentSpeakerID = sid
        }
        collectionView.reloadData()
        scrollToBottom()
    }

    // MARK: - Diarizer Binding
    
    private func bindDiarizer() {
        diarizer.$currentSpeakerID.receive(on: DispatchQueue.main).sink { [weak self] id in
            guard let self = self else { return }

            self.currentSpeakerID = id

            if id != nil {
                self.processBuffer()
            }

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

        diarizer.$segmentHistory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] history in
                self?.handleDiarizationRefinement(history)
            }
            .store(in: &diarizerCancellables)
    }

    // MARK: - Audio Configuration (🚨 FIXED VPIO ERRORS HERE)
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .record,
                mode: .measurement,
                options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setPreferredIOBufferDuration(0.02)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ [AudioSession] measurement mode active (raw audio)")
        } catch {
            print("❌ Session error: \(error)")
        }
    }
    
    private func startAudioEngine(forEnrollment: Bool = false) throws {
        let inputNode = audioEngine.inputNode

        // ❌ DISABLE hardware Voice Processing.
        // VPIO strips out acoustic anomalies that the VL1004 model actually
        // uses to differentiate between speakers. Raw .measurement audio gives
        // the most reliable voiceprints.
        if #available(iOS 13.0, *) {
            do {
                try inputNode.setVoiceProcessingEnabled(false)
                print("✅ [AudioEngine] Raw audio access enabled (VPIO off)")
            } catch {
                print("⚠️ [AudioEngine] Could not enable voice processing: \(error)")
            }
        }

        let inputFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            if self.isRecording { self.recognitionRequest?.append(buffer) }
            self.diarizer.handleAudio(
                buffer: buffer,
                targetFormat: AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: 16000, channels: 1, interleaved: false
                )!
            )
        }

        audioEngine.prepare()
        try audioEngine.start()
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
            
            self.processBuffer()
            
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
                var uniqueSenders = [String: String]()
                var order = [String]()
                
                for msg in self.messages {
                    if msg.senderID != "system" {
                        if uniqueSenders[msg.senderID] == nil {
                            uniqueSenders[msg.senderID] = msg.sender
                            order.append(msg.senderID)
                        }
                    }
                }
                
                for id in order {
                    participants.append(QuickCaptionsParticipantData(name: uniqueSenders[id] ?? "Unknown", senderID: id, summary: "Waiting for analysis..."))
                }
                
                summaryVC.participantsData = participants
                
                summaryNav.modalPresentationStyle = .pageSheet
                summaryNav.isModalInPresentation = true
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
            
            if let eventId = msg.eventId {
                self.diarizer.applyRetroactiveCorrection(forEventID: eventId, newName: newName)
            } else if let bubbleSpeakerID = msg.speakerID {
                self.diarizer.speakerNames[bubbleSpeakerID] = newName
            } else {
                if let key = self.diarizer.speakerNames.first(where: { $0.value == currentName })?.key {
                    self.diarizer.speakerNames[key] = newName
                }
            }

            for i in 0..<self.messages.count {
                if let eid = self.messages[i].eventId,
                   let historyEvent = self.diarizer.segmentHistory.first(where: { $0.id == eid }) {
                    
                    let sid = historyEvent.assignedSpeakerID
                    self.messages[i].speakerID = sid
                    self.messages[i].isIncoming = (sid != 0)
                    if sid == 0 {
                        self.messages[i].sender = self.diarizer.speakerNames[0] ?? "Me"
                    } else {
                        self.messages[i].sender = self.diarizer.speakerNames[sid] ?? "Speaker \(sid)"
                    }
                } else {
                    if self.messages[i].sender == currentName {
                        self.messages[i].sender = newName
                    }
                    if let sid = self.messages[i].speakerID,
                       let registeredName = self.diarizer.speakerNames[sid],
                       registeredName == newName {
                        self.messages[i].sender = newName
                    }
                }
            }
            
            self.collectionView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func handleDiarizationRefinement(_ history: [DiarizationEvent]) {
        guard !history.isEmpty else { return }
        var hasChanges = false
        for i in 0..<messages.count {
            if let timestamp = messages[i].timestamp {
                // Primary: find the most recent diarizer event before this message.
                // Fallback: use the very first diarizer event for messages that arrived
                // before the cold-start window closed (fixes the "other person first" case).
                let matchingEvent = history.last(where: { $0.timestamp <= timestamp })
                                 ?? history.first
                if let event = matchingEvent,
                   messages[i].speakerID != event.assignedSpeakerID {
                    let sid = event.assignedSpeakerID
                    messages[i].speakerID = sid
                    messages[i].isIncoming = (sid != 0)
                    messages[i].sender = sid == 0
                        ? (diarizer.speakerNames[0] ?? "Me")
                        : (diarizer.speakerNames[sid] ?? "Speaker \(sid)")
                    hasChanges = true
                }
            }
        }
        if hasChanges {
            UIView.performWithoutAnimation {
                self.collectionView.reloadData()
            }
        }
    }
}

extension Array where Element == QuickCaptionsChat {
    func toTranscriptString() -> String {
        return self.map { "\($0.sender): \($0.text)" }.joined(separator: "\n\n")
    }
}
