import UIKit
import Speech
import AVFoundation

class FamilyJoinViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSpeechRecognizerDelegate {

    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var micButton: UIButton!
    
    // MARK: - Properties
    var sessionTitle: String = "Family Session"
    // Use the Enum type we defined to prevent conversion errors
    var category: ChatCategory = .family
    var chatHistory: [(sender: String, message: String)] = []
    
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

    // THE MISSING LINK: This is the function your Storyboard is looking for!
    @IBAction func endSessionTapped(_ sender: Any) {
        // Stop audio before leaving to prevent background crashes
        if audioEngine.isRunning {
            stopRecording()
        }

        let storyboard = UIStoryboard(name: "Family.", bundle: nil)
        guard let summaryVC = storyboard.instantiateViewController(withIdentifier: "summaryScreen") as? FamilySummaryViewController else {
            print("❌ SummaryViewController not found!")
            return
        }
        
        // Pass data to summary
        summaryVC.category = self.category
        
        if let nav = navigationController {
            nav.pushViewController(summaryVC, animated: true)
        } else {
            self.present(summaryVC, animated: true)
        }
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
