//
//  QuickCaptioningViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import Speech
import AVFoundation

class QuickCaptioningViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIBarButtonItem!
    
    var messages: [QuickCaptionsChat] = []
    var otherPersonName = "Person 1"
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var isRecording = false
    var isPaused = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSpeechPermissions()
        setupAudioSession()
        setupMicButtonInteractions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidLoad()
        startSession(isUser: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRecording()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio Session Error: \(error)")
        }
    }
    
    // MARK: - Mic Button Logic
    
    private func setupMicButtonInteractions() {
        micButton.removeTarget(nil, action: nil, for: .allEvents)
        micButton.addTarget(self, action: #selector(micButtonDidPress), for: .touchDown)
        micButton.addTarget(self, action: #selector(micButtonDidRelease), for: [.touchUpInside, .touchUpOutside])
        updateMicButtonVisuals(isPressed: false)
    }
    
    @objc private func micButtonDidPress() {
        updateMicButtonVisuals(isPressed: true)
        restartRecording(isUser: true)
    }
    
    @objc private func micButtonDidRelease() {
        updateMicButtonVisuals(isPressed: false)
        restartRecording(isUser: false)
    }
    
    private func updateMicButtonVisuals(isPressed: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 21, weight: .regular, scale: .medium)
        if isPressed {
            micButton.setImage(UIImage(systemName: "microphone.fill", withConfiguration: config), for: .normal)
        } else {
            micButton.setImage(UIImage(systemName: "microphone.fill", withConfiguration: config), for: .normal)
        }
    }

    // MARK: - Speech Engine
    
    private func restartRecording(isUser: Bool) {
        stopRecordingEngine()
        
        // Small delay to ensure the engine fully stops before restarting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startSession(isUser: isUser)
        }
    }
    
    private func stopRecordingEngine() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        recognitionRequest = nil
        recognitionTask = nil
        
        // Removed finalizeLastBubble() call to prevent deleting messages
    }
    
    private func startSession(isUser: Bool) {
        if isPaused { return }
        
        if audioEngine.isRunning {
            stopRecordingEngine()
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        // Add bubble and capture its specific index
        addListeningBubble(isUser: isUser)
        let activeMessageIndex = messages.count - 1
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                // Update ONLY the bubble created for this session
                self.updateBubble(at: activeMessageIndex, with: result.bestTranscription.formattedString)
            }
            
            if error != nil {
                self.stopRecordingEngine()
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 else { return }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isRecording = true
    }
    
    private func stopRecording() {
        stopRecordingEngine()
        isRecording = false
    }
    
    // MARK: - Bubble Logic
    
    private func addListeningBubble(isUser: Bool) {
        let senderName = isUser ? "Me" : otherPersonName
        // Placeholder text. It will NOT be deleted now if no speech is detected.
        let newMessage = QuickCaptionsChat(text: "...", isIncoming: !isUser, sender: senderName)
        messages.append(newMessage)
        
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.insertItems(at: [indexPath])
        scrollToBottom()
    }
    
    private func updateBubble(at index: Int, with text: String) {
        DispatchQueue.main.async {
            // Safety check to ensure we don't crash if array changed unexpectedly
            guard index < self.messages.count else { return }
            
            // Only update if the text is meaningful
            self.messages[index].text = text
            
            // Reload the specific item without animation to prevent flickering
            UIView.performWithoutAnimation {
                self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                self.scrollToBottom()
            }
        }
    }

    // MARK: - UI Actions
    
    @IBAction func didTapStopButton(_ sender: UIBarButtonItem) {
        stopRecording()
        
        let actionSheet = UIAlertController(title: "End Session?", message: "This will save the transcript.", preferredStyle: .alert)
        let endAction = UIAlertAction(title: "End Session", style: .destructive) { [weak self] _ in
            self?.navigateToSummary()
        }
        actionSheet.addAction(endAction)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(actionSheet, animated: true)
    }
    
    private func navigateToSummary() {
        let storyboard = UIStoryboard(name: "Quick Captions", bundle: nil)
        
        if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
           let summaryVC = summaryNav.topViewController as? SummaryViewController {
            
            let participants = [
                QuickCaptionsParticipants(
                    name: self.otherPersonName,
                    summary: "Transcript generated via Live Captioning."
                )
            ]
            summaryVC.participantsData = participants
            summaryNav.modalPresentationStyle = .pageSheet
            self.present(summaryNav, animated: true)
        }
    }
    
    private func showRenameAlert() {
        let wasRecording = isRecording
        if wasRecording { stopRecording() }
        
        let alert = UIAlertController(title: "Rename Speaker", message: "Enter name:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = self.otherPersonName
            tf.autocapitalizationType = .words
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self.otherPersonName = newName
                self.updatePastMessagesSenderName()
            }
            if wasRecording { self.startSession(isUser: false) }
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            if wasRecording { self?.startSession(isUser: false) }
        }))
        self.present(alert, animated: true)
    }
    
    private func updatePastMessagesSenderName() {
        for (index, message) in messages.enumerated() {
            if message.isIncoming {
                messages[index].sender = otherPersonName
            }
        }
        collectionView.reloadData()
    }
    
    // MARK: - CollectionView DataSource & Layout
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.minimumLineSpacing = 10
            layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        }
        collectionView.keyboardDismissMode = .interactive
    }
    
    private func setupSpeechPermissions() {
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.micButton.isEnabled = (authStatus == .authorized)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QCIncomingCell", for: indexPath) as! QuickCaptionsIncomingCell
            cell.messageLabel.text = message.text
            cell.nameLabel.text = message.sender
            cell.onLabelTapped = { [weak self] in self?.showRenameAlert() }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QCOutgoingCell", for: indexPath) as! QuickCaptionsOutgoingCell
            cell.QCmessageLabel.text = message.text
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 40
        let font = UIFont.systemFont(ofSize: 17)
        let text = messages[indexPath.row].text
        let boundingBox = text.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return CGSize(width: collectionView.bounds.width, height: boundingBox.height + 60)
    }
    
    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        collectionView.scrollToItem(at: IndexPath(item: messages.count - 1, section: 0), at: .bottom, animated: true)
    }
}
