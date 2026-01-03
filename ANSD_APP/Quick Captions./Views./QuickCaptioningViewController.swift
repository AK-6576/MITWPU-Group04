//
//  QuickCaptioningViewController.swift
//  ANSD_APP
//
//  Real-time Speech-to-Text with Speaker Recognition
//

import UIKit
import Speech
import AVFoundation

class QuickCaptioningViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    // MARK: - Variables
    var messages: [QCChatMessage] = []
    var isPaused = false
    var otherPersonName = "Person 1"
    var isRecording = false
    
    // MARK: - Speech Recognition Properties
    private var speechManager: SpeechRecognitionManager?
    private var lastTranscriptionText: String = ""
    private var currentSpeaker: String = "You"
    
    // Speaker tracking
    private var speakerNames: [String: String] = [
        "speaker_0": "You",
        "speaker_1": "Person 1"
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupSpeechRecognition()
        requestPermissions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRecording()
    }
    
    // MARK: - Setup
    func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.minimumLineSpacing = 4
            layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        }
        
        collectionView.keyboardDismissMode = .interactive
    }
    
    func setupSpeechRecognition() {
        // Always use Legacy Speech Manager since iOS 26 APIs aren't available yet
        speechManager = LegacySpeechManager()
        
        speechManager?.onTranscriptionUpdate = { [weak self] text, speakerId, isFinal in
            self?.handleTranscription(text: text, speakerId: speakerId, isFinal: isFinal)
        }
        
        speechManager?.onError = { [weak self] error in
            self?.showError(error)
        }
    }
    
    func requestPermissions() {
        Task {
            // Request microphone permission
            let micGranted: Bool
            if #available(iOS 17.0, *) {
                micGranted = await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            } else {
                micGranted = await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            }
            
            guard micGranted else {
                await MainActor.run {
                    showPermissionAlert(type: "Microphone")
                }
                return
            }
            
            // Request speech recognition permission
            let speechGranted = await speechManager?.requestAuthorization() ?? false
            
            guard speechGranted else {
                await MainActor.run {
                    showPermissionAlert(type: "Speech Recognition")
                }
                return
            }
            
            // Auto-start recording
            await MainActor.run {
                self.startRecording()
            }
        }
    }
    
    // MARK: - Speech Recognition Control
    func startRecording() {
        guard !isRecording else { return }
        
        Task {
            do {
                try await speechManager?.startRecording()
                
                await MainActor.run {
                    isRecording = true
                    updateMicButton()
                }
            } catch {
                await MainActor.run {
                    showError(error)
                }
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        Task {
            try? await speechManager?.stopRecording()
            
            await MainActor.run {
                isRecording = false
                updateMicButton()
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    // MARK: - Transcription Handling
    func handleTranscription(text: String, speakerId: String?, isFinal: Bool) {
        guard !text.isEmpty else { return }
        
        // Determine if this is from user or other person
        let isIncoming = speakerId != "speaker_0" && speakerId != "You"
        let displayName = getSpeakerName(for: speakerId)
        
        // Check if we need to create a new message or update existing
        if isFinal {
            // Create final message
            if lastTranscriptionText != text {
                addMessage(text: text, isIncoming: isIncoming, sender: displayName)
                lastTranscriptionText = text
            }
        } else {
            // Update or create partial message
            updateOrAddPartialMessage(text: text, isIncoming: isIncoming, sender: displayName)
        }
    }
    
    func getSpeakerName(for speakerId: String?) -> String {
        guard let id = speakerId else { return currentSpeaker }
        
        if id == "speaker_0" || id == "You" {
            return "You"
        }
        
        // Check if we have a custom name for this speaker
        return speakerNames[id] ?? otherPersonName
    }
    
    func addMessage(text: String, isIncoming: Bool, sender: String) {
        let message = QCChatMessage(
            text: text,
            isIncoming: isIncoming,
            sender: sender
        )
        
        messages.append(message)
        
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.insertItems(at: [indexPath])
        scrollToBottom()
    }
    
    func updateOrAddPartialMessage(text: String, isIncoming: Bool, sender: String) {
        // Check if last message is from same speaker and can be updated
        if messages.count > 0 {
            let lastIndex = messages.count - 1
            if messages[lastIndex].isIncoming == isIncoming && messages[lastIndex].sender == sender {
                // Update existing message
                messages[lastIndex] = QCChatMessage(
                    text: text,
                    isIncoming: isIncoming,
                    sender: sender
                )
                let indexPath = IndexPath(item: lastIndex, section: 0)
                collectionView.reloadItems(at: [indexPath])
                return
            }
        }
        
        // Add new partial message
        addMessage(text: text, isIncoming: isIncoming, sender: sender)
    }
    
    // MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QCIncomingCell", for: indexPath) as! QCIncomingCell
            cell.messageLabel.text = message.text
            
            // Use the actual sender name
            if message.sender == "Person 1" {
                cell.nameLabel.text = self.otherPersonName
            } else {
                cell.nameLabel.text = message.sender
            }
            
            cell.onLabelTapped = { [weak self] in
                self?.showRenameAlert()
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QCOutgoingCell", for: indexPath) as! QCOutgoingCell
            cell.QCmessageLabel.text = message.text
            return cell
        }
    }
    
    // MARK: - Rename Alert
    func showRenameAlert() {
        let wasRecording = isRecording
        if isRecording { toggleRecording() }
        if !isPaused { togglePauseState() }
        
        let alert = UIAlertController(title: "Rename Speaker", message: "Enter name:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = self.otherPersonName
            tf.autocapitalizationType = .words
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self.otherPersonName = newName
                // Update speaker mapping
                self.speakerNames["speaker_1"] = newName
                self.collectionView.reloadData()
            }
            self.togglePauseState()
            if wasRecording { self.toggleRecording() }
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            if wasRecording { self.toggleRecording() }
        })
        self.present(alert, animated: true)
    }

    // MARK: - Button Actions
    @IBAction func didTapPauseButton(_ sender: UIButton) {
        togglePauseState()
        toggleRecording()
    }
    
    func togglePauseState() {
        isPaused = !isPaused
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imgName = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
    }
    
    func updateMicButton() {
        let config = UIImage.SymbolConfiguration(scale: .large)
        let imgName = isRecording ? "mic.fill" : "mic.slash.fill"
        let color: UIColor = isRecording ? .systemRed : .systemGray
        micButton.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
        micButton.tintColor = color
    }
    
    @IBAction func didTapStopButton(_ sender: UIButton) {
        stopRecording()
        
        if !isPaused { togglePauseState() }
        
        let actionSheet = UIAlertController(title: "End Session?", message: "Are you sure?", preferredStyle: .alert)
        
        let endAction = UIAlertAction(title: "End Session", style: .destructive) { _ in
            self.showSummary()
        }
        
        actionSheet.addAction(endAction)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            if self.isPaused { self.togglePauseState() }
            self.startRecording()
        })
        
        self.present(actionSheet, animated: true)
    }
    
    func showSummary() {
        let storyboard = UIStoryboard(name: "Quick Captions", bundle: nil)
        
        if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
           let summaryVC = summaryNav.topViewController as? SummaryViewController {
            
            // Generate summaries from actual conversation
            let participantsData = generateParticipantSummaries()
            summaryVC.participantsData = participantsData
            
            summaryNav.modalPresentationStyle = .pageSheet
            self.present(summaryNav, animated: true, completion: nil)
        }
    }
    
    func generateParticipantSummaries() -> [QCParticipantData] {
        var summaries: [String: [String]] = [:]
        
        // Group messages by sender
        for message in messages {
            let sender = message.isIncoming ? otherPersonName : "You"
            if summaries[sender] == nil {
                summaries[sender] = []
            }
            summaries[sender]?.append(message.text)
        }
        
        // Create participant data
        var participants: [QCParticipantData] = []
        
        for (name, texts) in summaries {
            // Take first 3 messages or all if less
            let summary = texts.prefix(3).joined(separator: " ")
            participants.append(QCParticipantData(name: name, summary: summary))
        }
        
        return participants
    }
    
    // MARK: - Layout Helpers
    func scrollToBottom() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - 32, height: 100)
    }
    
    // MARK: - Error Handling
    func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showPermissionAlert(type: String) {
        let alert = UIAlertController(
            title: "\(type) Access Required",
            message: "Please enable \(type) access in Settings to use this feature.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - =====================================
// MARK: - Speech Recognition Manager Protocol
// MARK: - =====================================

protocol SpeechRecognitionManager {
    var onTranscriptionUpdate: ((String, String?, Bool) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
    
    func requestAuthorization() async -> Bool
    func startRecording() async throws
    func stopRecording() async throws
}

// MARK: - =====================================
// MARK: - Legacy Speech Manager (iOS 10+)
// MARK: - =====================================

class LegacySpeechManager: NSObject, SpeechRecognitionManager {
    var onTranscriptionUpdate: ((String, String?, Bool) -> Void)?
    var onError: ((Error) -> Void)?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func startRecording() async throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Try on-device recognition if available
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.onError?(error)
                }
                return
            }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                
                // Legacy doesn't have speaker ID, default to "You"
                DispatchQueue.main.async {
                    self?.onTranscriptionUpdate?(text, "You", isFinal)
                }
            }
        }
        
        // Install audio tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stopRecording() async throws {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        try AVAudioSession.sharedInstance().setActive(false)
    }
}

// MARK: - =====================================
// MARK: - Supporting Models & Errors
// MARK: - =====================================

enum SpeechError: Error, LocalizedError {
    case initializationFailed
    case requestCreationFailed
    case modelNotInstalled
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize speech recognition"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        case .modelNotInstalled:
            return "Speech model not installed"
        }
    }
}
