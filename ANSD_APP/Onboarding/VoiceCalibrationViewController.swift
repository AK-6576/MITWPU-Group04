//
//  VoiceCalibrationViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 19/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - Calibration Phase
// Mirrors Siri's "Hey Siri" setup: one tap starts all three sentences back-to-back.
private enum CalibrationPhase {
    case ready                  // Waiting for the user to tap once
    case countdown(Int)         // 3-2-1 countdown before recording starts
    case recording(Int)         // Actively recording sentence at index
    case betweenSentences(Int)  // Brief pause before the next sentence
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

    // MARK: - Data
    private let sentences = [
        "What is the weather going to be like today?",
        "Set a timer for exactly five minutes.",
        "Send a message to let them know I am on my way."
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCard()
        setupVisualizer()
        requestMicrophoneAccess()
        updatePromptText(index: 0)
        phase = .ready
    }

    // MARK: - UI Setup

    private func setupCard() {
        promptCardView.layer.cornerRadius = 20
        promptCardView.layer.shadowColor = UIColor.black.cgColor
        promptCardView.layer.shadowOpacity = 0.07
        promptCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        promptCardView.layer.shadowRadius = 12
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

    // MARK: - State → UI

    private func updateUI(for phase: CalibrationPhase) {
        switch phase {

        case .ready:
            setButton(title: "Start Voice Setup", image: "mic.fill", color: view.tintColor, enabled: true)
            instructionLabel.text = "Tap once. Read all three sentences."
            animateBarsToResting()

        case .countdown(let n):
            setButton(title: "Starting in \(n)…", image: "timer", color: .systemOrange, enabled: false)
            instructionLabel.text = "Get ready to speak…"
            animateBarsToResting()

        case .recording(let idx):
            let ordinals = ["first", "second", "third"]
            let label = idx < ordinals.count ? ordinals[idx] : "\(idx + 1)th"
            setButton(title: "Listening…  (\(idx + 1) of \(sentences.count))", image: "waveform", color: .systemRed, enabled: false)
            instructionLabel.text = "Read the sentence aloud (\(label) of three)"

        case .betweenSentences(let nextIdx):
            let next = min(nextIdx, sentences.count - 1)
            setButton(title: "Next sentence in 2s…", image: "arrow.right.circle", color: .systemOrange, enabled: false)
            instructionLabel.text = "Well done! Next coming up…"
            updatePromptText(index: next)
            animateBarsToResting()

        case .finished:
            setButton(title: "Go to Home", image: "checkmark.circle.fill", color: view.tintColor, enabled: true)
            instructionLabel.text = "Voice profile saved! Tap to continue."
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

    // MARK: - Prompt

    private func updatePromptText(index: Int) {
        guard index < sentences.count else { return }
        UIView.transition(with: promptTextLabel, duration: 0.35, options: .transitionCrossDissolve) {
            self.promptTextLabel.text = self.sentences[index]
        }
    }

    // MARK: - Microphone Permission

    private func requestMicrophoneAccess() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                if !allowed {
                    self?.instructionLabel.text = "Microphone access is required in Settings."
                    self?.recordButton.isEnabled = false
                }
            }
        }
    }

    // MARK: - Audio Recorder

    private func setupAudioRecorder(for sentenceIndex: Int) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = docs.appendingPathComponent("VoiceProfile_Sentence\(sentenceIndex).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
        } catch {
            print("VoiceCalibration: Recorder setup failed — \(error)")
        }
    }

    // MARK: - Main Flow (Siri-style: one tap, continuous)

    @IBAction func recordButtonTapped(_ sender: UIButton) {
        switch phase {
        case .ready:
            beginCountdown()
        case .finished:
            navigateToHome()
        default:
            break // All other phases are automatic
        }
    }

    /// Step 1 — 3-2-1 countdown before recording
    private func beginCountdown() {
        var count = 3
        phase = .countdown(count)

        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            count -= 1
            if count > 0 {
                self.phase = .countdown(count)
            } else {
                timer.invalidate()
                self.phaseTimer = nil
                self.recordSentence(index: 0)
            }
        }
    }

    /// Step 2 — Record one sentence, then chain to the next or finish
    private func recordSentence(index: Int) {
        guard index < sentences.count else {
            self.phase = .finished
            return
        }

        updatePromptText(index: index)
        phase = .recording(index)

        setupAudioRecorder(for: index)
        audioRecorder?.record()
        startMeteringAnimation()

        // Each sentence gets 5 seconds of recording time
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.audioRecorder?.stop()
            self.stopMeteringAnimation()

            if index + 1 < self.sentences.count {
                // Pause for 2 seconds then move to next sentence
                self.phase = .betweenSentences(index + 1)
                self.phaseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    self?.phaseTimer = nil
                    self?.recordSentence(index: index + 1)
                }
            } else {
                // All sentences done
                self.phase = .finished
            }
        }
    }

    // MARK: - Visualizer Animation

    private func startMeteringAnimation() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let rec = self.audioRecorder else { return }
            rec.updateMeters()
            let power = rec.averagePower(forChannel: 0)
            let level = CGFloat(max(0, min(1, (power + 60) / 60)))
            self.animateBars(level: level)
        }
    }

    private func stopMeteringAnimation() {
        meteringTimer?.invalidate()
        meteringTimer = nil
    }

    private func animateBars(level: CGFloat) {
        UIView.animate(withDuration: 0.05) {
            for (i, bar) in self.audioBars.enumerated() {
                let wave = CGFloat(sin(Double(i) * 0.5 + Date().timeIntervalSince1970 * 8) * 0.3)
                let barLevel = max(0, level + wave)
                let maxH: CGFloat = 48, minH: CGFloat = 6
                let h = minH + barLevel * (maxH - minH)
                bar.transform = CGAffineTransform(scaleX: 1, y: max(1, h / minH))
                bar.backgroundColor = self.view.tintColor.withAlphaComponent(0.4 + level * 0.6)
            }
        }
    }

    private func animateBarsToResting() {
        UIView.animate(withDuration: 0.4, delay: 0,
                       usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3) {
            for bar in self.audioBars {
                bar.transform = .identity
                bar.backgroundColor = self.view.tintColor.withAlphaComponent(0.35)
            }
        }
    }

    // MARK: - Navigation

    private func navigateToHome() {
        performSegue(withIdentifier: "calibrationToHome", sender: self)
    }

    // MARK: - Cleanup

    deinit {
        phaseTimer?.invalidate()
        meteringTimer?.invalidate()
        audioRecorder?.stop()
    }
}
