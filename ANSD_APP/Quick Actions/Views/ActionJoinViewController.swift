//
//  ActionJoinViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 05/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class ActionJoinViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSpeechRecognizerDelegate {

    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var micButton: UIButton!
    
    // MARK: - Properties
    var category: String = "Family"
    var chatHistory: [(sender: String, message: String)] = []
    var sessionTitle: String = "Session" {
        didSet {
            self.title = sessionTitle
        }
    }
    
    // Speech Engine Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = sessionTitle
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupSpeech()
        addMessage(sender: "System", text: "Tap the mic to start speaking.")
    }
    
    func setupSpeech() {
        micButton.isEnabled = false
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.micButton.isEnabled = (authStatus == .authorized)
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func micButtonTapped(_ sender: UIButton) {
        if audioEngine.isRunning {
            stopRecording()
        } else {
            startRecording()
        }
    }

    @IBAction func endSessionTapped(_ sender: Any) {
        // 1. Initialize the Alert
        let alert = UIAlertController(
            title: "End Session?",
            message: "This will stop transcription and generate a summary.",
            preferredStyle: .alert
        )
        
        // 2. Define the "End Session" Action (Destructive)
        let endAction = UIAlertAction(title: "End Session", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Block 1: Safety Cleanup (Stopping Audio)
            if self.audioEngine.isRunning {
                self.stopRecording()
            }
            
            // 3. Trigger Navigation (Modal)
            self.navigateToSummary()
        }
        
        // 4. Define the Cancel Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // 5. Add actions and present the alert
        alert.addAction(endAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    func navigateToSummary() {
        let storyboard = UIStoryboard(name: "Action", bundle: nil)
        
        guard let summaryVC = storyboard.instantiateViewController(withIdentifier: "summaryScreen") as? BaseSummaryViewController else {
            print("❌ SummaryViewController not found!")
            return
        }

        summaryVC.category = self.category
        
        // 1. Wrap your summaryVC in a new Navigation Controller
        let navController = UINavigationController(rootViewController: summaryVC)
        
        // 2. Set the modal style on the Nav Controller, not the summaryVC
        navController.modalPresentationStyle = .pageSheet
        
        // 3. Present the Navigation Controller
        self.present(navController, animated: true, completion: nil)
    }
    
    // MARK: - Speech Implementation
    func startRecording() {
        if recognitionTask != nil { recognitionTask?.cancel(); recognitionTask = nil }
        
        micButton.setTitle("Stop", for: .normal)
        micButton.backgroundColor = .systemRed
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        recognitionRequest?.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                if result.isFinal {
                    self.addMessage(sender: "You", text: result.bestTranscription.formattedString)
                    self.stopRecording()
                }
            }
            if error != nil { self.stopRecording() }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask = nil
        recognitionRequest = nil
        
        micButton.setTitle("Record", for: .normal)
        micButton.backgroundColor = .systemBlue
    }
    
    func addMessage(sender: String, text: String) {
        chatHistory.append((sender: sender, message: text))
        collectionView.reloadData()
        
        if chatHistory.count > 0 {
            let lastItem = chatHistory.count - 1
            collectionView.scrollToItem(at: IndexPath(item: lastItem, section: 0), at: .bottom, animated: true)
        }
    }

    // MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return chatHistory.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let chat = chatHistory[indexPath.row]
        
        if chat.sender == "You" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutgoingCell", for: indexPath) as! OutgoingCell
            cell.messageLabel.text = chat.message
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IncomingCell", for: indexPath) as! IncomingCell
            cell.messageLabel.text = chat.message
            cell.nameLabel.text = chat.sender
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 80)
    }
}
