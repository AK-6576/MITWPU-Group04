//
//  VoiceCalibrationViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 19/02/26.
//  Modified to use FluidAudio on 11/05/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Accelerate
import FirebaseAuth
import FluidAudio

// MARK: - Calibration Phase
private enum CalibrationPhase {
    case ready                  // Waiting for the user to tap once
    case countdown(Int)         // 3-2-1 countdown before recording starts
    case recording(Int)         // Actively recording sentence at index
    case verifying(Int)         // Processing & verifying voice after a sentence
    case betweenSentences(Int)  // Brief pause before the next sentence
    case mismatch               // Voice mismatch detected — retry
    case finished               // All done — show Finish button
}

class VoiceCalibrationViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var promptCardView: UIView!
    @IBOutlet weak var promptTextLabel: UILabel!
    @IBOutlet weak var visualizerContainerView: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!

    // MARK: - State
    private var phase: CalibrationPhase = .ready {
        didSet { updateUI(for: phase) }
    }

    // MARK: - Timers & Audio
    private var audioRecorder: AVAudioRecorder?
    private var meteringTimer: Timer?
    private var phaseTimer: Timer?

    // MARK: - Visualizer
    private var audioBars: [UIView] = []
    private let barCount = 28

    // MARK: - FluidAudio Model
    private var embedder: SpeakerEmbedder?
    private let requiredSamples = 96000  // 6 seconds × 16kHz
    private let similarityThreshold: Float = 0.65 // Optimized for FluidAudio embeddings

    // MARK: - Voice Embeddings
    private var sentenceEmbeddings: [[Float]] = []
    
    // MARK: - Sentence Status Indicators
    private var statusLabels: [UILabel] = []
    private var statusStack: UIStackView!

    // MARK: - Data
    private let sentences = [
        "The quick brown fox jumps over the lazy dog near the river bank.",
        "Please verify my identity by recognizing my unique voice pattern.",
        "Artificial intelligence is transforming the way we communicate daily."
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Voice Setup"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        setupCard()
        setupVisualizer()
        setupSentenceStatusIndicators()
        setupFluidAudioEmbedder()
        requestMicrophoneAccess()
        updatePromptText(index: 0)
        phase = .ready
    }

    private func setupFluidAudioEmbedder() {
        Task {
            do {
                self.embedder = try await SpeakerEmbedder.loadFromHub()
                print("VoiceCalibration: FluidAudio SpeakerEmbedder loaded successfully")
            } catch {
                print("VoiceCalibration: Failed to load FluidAudio Embedder — \(error)")
            }
        }
    }

    // MARK: - UI Setup
    private func setupCard() {
        promptCardView.layer.cornerRadius = 20
        promptCardView.backgroundColor = .secondarySystemBackground
    }

    private func setupVisualizer() {
        visualizerContainerView.subviews.forEach { $0.removeFromSuperview() }
        audioBars.removeAll()

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        visualizerContainerView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: visualizerContainerView.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: visualizerContainerView.trailingAnchor, constant: -4),
            stack.centerYAnchor.constraint(equalTo: visualizerContainerView.centerYAnchor),
            stack.heightAnchor.constraint(equalTo: visualizerContainerView.heightAnchor)
        ])

        for _ in 0..<barCount {
            let bar = UIView()
            bar.backgroundColor = view.tintColor.withAlphaComponent(0.35)
            bar.layer.cornerRadius = 3
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.widthAnchor.constraint(equalToConstant: 4).isActive = true
            bar.heightAnchor.constraint(equalToConstant: 6).isActive = true
            audioBars.append(bar)
            stack.addArrangedSubview(bar)
        }
    }
    
    private func setupSentenceStatusIndicators() {
        statusStack = UIStackView()
        statusStack.axis = .horizontal
        statusStack.distribution = .fillEqually
        statusStack.spacing = 12
        statusStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusStack)
        
        NSLayoutConstraint.activate([
            statusStack.topAnchor.constraint(equalTo: promptCardView.bottomAnchor, constant: 16),
            statusStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40),
            statusStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40),
            statusStack.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        for i in 0..<sentences.count {
            let label = UILabel()
            label.text = "Sentence \(i + 1)"
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 13, weight: .medium)
            label.textColor = .systemGray
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            label.backgroundColor = .systemGray6
            statusLabels.append(label)
            statusStack.addArrangedSubview(label)
        }
    }
    
    private func updateSentenceStatus(index: Int, verified: Bool) {
        guard index < statusLabels.count else { return }
        UIView.animate(withDuration: 0.3) {
            if verified {
                self.statusLabels[index].text = "Verified"
                self.statusLabels[index].textColor = .white
                self.statusLabels[index].backgroundColor = .systemGreen
            } else {
                self.statusLabels[index].text = "Mismatch"
                self.statusLabels[index].textColor = .white
                self.statusLabels[index].backgroundColor = .systemRed
            }
        }
    }
    
    private func resetSentenceStatuses() {
        for (i, label) in statusLabels.enumerated() {
            UIView.animate(withDuration: 0.3) {
                label.text = "Sentence \(i + 1)"
                label.textColor = .systemGray
                label.backgroundColor = .systemGray6
            }
        }
    }

    private func updateUI(for phase: CalibrationPhase) {
        switch phase {
        case .ready:
            setButton(title: "Start Voice Setup", image: "mic.fill", color: view.tintColor, enabled: true)
            instructionLabel.text = "Tap once. Read all three sentences."
            animateBarsToResting()
        case .countdown(let n):
            setButton(title: "Starting in \(n)…", image: "timer", color: .systemOrange, enabled: false)
            instructionLabel.text = "Get ready to speak…"
        case .recording(let idx):
            setButton(title: "Listening…  (\(idx + 1) of \(sentences.count))", image: "waveform", color: .systemRed, enabled: false)
            instructionLabel.text = "Read the sentence aloud"
        case .verifying(let idx):
            setButton(title: "Verifying voice…", image: "person.wave.2.fill", color: .systemPurple, enabled: false)
            instructionLabel.text = "Checking voice identity for sentence \(idx + 1)…"
        case .betweenSentences(let nextIdx):
            setButton(title: "Next sentence in 2s…", image: "arrow.right.circle", color: .systemOrange, enabled: false)
            instructionLabel.text = "Voice verified! Next coming up…"
            updatePromptText(index: nextIdx)
            animateBarsToResting()
        case .mismatch:
            setButton(title: "Try Again", image: "arrow.counterclockwise", color: .systemRed, enabled: true)
            instructionLabel.text = "Voice mismatch detected."
            animateBarsToResting()
        case .finished:
            setButton(title: "Go to Home", image: "checkmark.circle.fill", color: .systemGreen, enabled: true)
            instructionLabel.text = "Voice profile saved."
            animateBarsToResting()
        }
    }

    private func setButton(title: String, image: String, color: UIColor, enabled: Bool) {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.imagePadding = 8
        config.image = UIImage(systemName: image)
        config.title = title
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        recordButton.configuration = config
        recordButton.isEnabled = enabled
    }

    private func updatePromptText(index: Int) {
        guard index < sentences.count else { return }
        UIView.transition(with: promptTextLabel, duration: 0.35, options: .transitionCrossDissolve) {
            self.promptTextLabel.text = self.sentences[index]
        }
    }

    private func requestMicrophoneAccess() {
        let handlePermission: (Bool) -> Void = { [weak self] allowed in
            DispatchQueue.main.async {
                if allowed { self?.phase = .ready }
                else { self?.instructionLabel.text = "Microphone access required." }
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission(handlePermission)
    }

    @IBAction func recordButtonTapped(_ sender: UIButton) {
        if case .ready = phase {
            sentenceEmbeddings.removeAll()
            resetSentenceStatuses()
            beginCountdown()
        } else if case .mismatch = phase {
            sentenceEmbeddings.removeAll()
            resetSentenceStatuses()
            beginCountdown()
        } else if case .finished = phase {
            navigateToHome()
        }
    }

    private func beginCountdown() {
        var count = 3
        phase = .countdown(count)
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            count -= 1
            if count > 0 { self?.phase = .countdown(count) }
            else { timer.invalidate(); self?.recordSentence(index: 0) }
        }
    }

    private func recordSentence(index: Int) {
        guard index < sentences.count else {
            saveVoiceProfile()
            phase = .finished
            return
        }
        phase = .recording(index)
        setupAudioRecorder(for: index)
        audioRecorder?.record()
        startMeteringAnimation()
        
        Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { [weak self] _ in
            self?.audioRecorder?.stop()
            self?.stopMeteringAnimation()
            self?.phase = .verifying(index)
            self?.verifySentence(index: index)
        }
    }

    private func setupAudioRecorder(for index: Int) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("Calibration_\(index).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try? AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
    }

    private func verifySentence(index: Int) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("Calibration_\(index).m4a")
        
        extractAudioSamples(from: url) { [weak self] samples in
            guard let self = self, let samples = samples, let embedder = self.embedder else { return }
            
            Task {
                do {
                    let embedding = try await embedder.embed(samples: samples, sampleRate: 16000)
                    await MainActor.run {
                        self.processEmbedding(embedding, at: index)
                    }
                } catch {
                    print("VoiceCalibration: Error embedding sentence \(index) — \(error)")
                }
            }
        }
    }

    private func processEmbedding(_ embedding: [Float], at index: Int) {
        if sentenceEmbeddings.isEmpty {
            sentenceEmbeddings.append(embedding)
            updateSentenceStatus(index: index, verified: true)
            proceed(index: index)
            return
        }
        
        let similarity = cosineSim(embedding, sentenceEmbeddings[0])
        if similarity >= similarityThreshold {
            sentenceEmbeddings.append(embedding)
            updateSentenceStatus(index: index, verified: true)
            proceed(index: index)
        } else {
            updateSentenceStatus(index: index, verified: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.phase = .mismatch }
        }
    }

    private func proceed(index: Int) {
        if index + 1 < sentences.count {
            phase = .betweenSentences(index + 1)
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                self?.recordSentence(index: index + 1)
            }
        } else {
            saveVoiceProfile()
            phase = .finished
        }
    }

    private func extractAudioSamples(from url: URL, completion: @escaping ([Float]?) -> Void) {
        DispatchQueue.global().async {
            do {
                let file = try AVAudioFile(forReading: url)
                let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
                let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16000 * 7)!
                try file.read(into: buffer)
                let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
                completion(samples)
            } catch { completion(nil) }
        }
    }

    private func saveVoiceProfile() {
        guard let uid = Auth.auth().currentUser?.uid, !sentenceEmbeddings.isEmpty else { return }
        let avg = averageEmbeddings(sentenceEmbeddings)
        VoiceProfileManager.shared.saveVoiceProfile(ownerUID: uid, name: "Me", embedding: avg)
    }

    private func averageEmbeddings(_ embeddings: [[Float]]) -> [Float] {
        let dim = embeddings[0].count
        var avg = [Float](repeating: 0, count: dim)
        for e in embeddings { for i in 0..<dim { avg[i] += e[i] } }
        for i in 0..<dim { avg[i] /= Float(embeddings.count) }
        return normalize(avg)
    }

    private func normalize(_ v: [Float]) -> [Float] {
        var norm: Float = 0
        vDSP_svesq(v, 1, &norm, vDSP_Length(v.count))
        let mag = sqrt(norm) + 1e-9
        var res = [Float](repeating: 0, count: v.count)
        vDSP_vsdiv(v, 1, [mag], &res, 1, vDSP_Length(v.count))
        return res
    }

    private func cosineSim(_ v1: [Float], _ v2: [Float]) -> Float {
        var dot: Float = 0
        vDSP_dotpr(v1, 1, v2, 1, &dot, vDSP_Length(v1.count))
        return dot
    }

    private func navigateToHome() {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        if let homeNav = storyboard.instantiateViewController(withIdentifier: "HomeNav") as? UINavigationController {
            view.window?.rootViewController = homeNav
            UIView.transition(with: view.window!, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }

    private func startMeteringAnimation() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.audioRecorder?.updateMeters()
            let power = self?.audioRecorder?.averagePower(forChannel: 0) ?? -60
            let level = CGFloat(max(0, min(1, (power + 60) / 60)))
            self?.animateBars(level: level)
        }
    }

    private func stopMeteringAnimation() { meteringTimer?.invalidate() }

    private func animateBars(level: CGFloat) {
        for (i, bar) in audioBars.enumerated() {
            let wave = CGFloat(sin(Double(i) * 0.5 + Date().timeIntervalSince1970 * 8) * 0.3)
            let h = 6 + (level + wave) * 42
            bar.transform = CGAffineTransform(scaleX: 1, y: max(1, h / 6))
        }
    }

    private func animateBarsToResting() {
        for bar in audioBars { bar.transform = .identity }
    }
}
