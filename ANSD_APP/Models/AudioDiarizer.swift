//
//  AudioDiarizer.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 20/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import AVFoundation
import CoreML
import Accelerate
import SoundAnalysis
import Combine

struct DiarizationEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let vector: [Float]
    var assignedSpeakerID: Int
    var confidence: Float
    let locationTag: String?
}

class AudioDiarizer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var audioConverter: AVAudioConverter?

    private var model: VL1004?

    // MARK: - Sliding Window Configuration
    // requiredSamples = 96000  →  6 seconds of audio at 16 kHz
    // stride          = 4800   →  300 ms slide interval at 16 kHz
    private let requiredSamples = 96000
    private let stride          = 4800
    private var collectedSamples: [Float] = []

    // MARK: - Advanced Diarization Parameters
    private let matchThreshold: Float = 0.60
    private let deadzoneThreshold: Float = 0.48 // Widened slightly to catch more noise
    private let learningThreshold: Float = 0.85 // ⭐️ EXTREMELY STRICT: Only learn from clean audio
    private let learningRate: Float = 0.05
    private var isSilent: Bool = false
    
    // ⭐️ Temporal Continuity & Probation
    private var unknownFrameCount = 0
    private let probationLimit = 3
    private var lastMatchedSpeakerID: Int? = nil // Tracks who spoke 300ms ago
    
    // MARK: - SoundAnalysis Speech Gate
    private let speechGate     = SpeechActivityGate()
    private var soundAnalyzer:  SNAudioStreamAnalyzer?
    private let analysisQueue  = DispatchQueue(label: "com.ansd.soundanalysis", qos: .userInitiated)
    private var analysisFrame:  AVAudioFramePosition = 0

    // MARK: - Frame Voting
    private let votingThreshold = 3
    private var voteCount:    [Int: Int] = [:]
    private var leadingVoteID: Int?

    // MARK: - Speaker Memory
    @Published var speakerProfiles: [Int: [Float]] = [:]
    @Published var speakerNames:    [Int: String] = [:]
    @Published var currentStatus:   String = "Ready"
    @Published var confidence:      String = "--"
    @Published var isRunning               = false
    @Published var currentSpeakerID: Int?  = nil

    public var currentLocation: String? = nil
    @Published var segmentHistory: [DiarizationEvent] = []

    private var isEnrolling = false
    private var enrollmentCompletion: ((Bool) -> Void)?

    // MARK: - Serial Inference Queue
    private let inferenceQueue = DispatchQueue(label: "com.ansd.audiodiarizer.inference", qos: .userInitiated)
    private var pendingInferenceCount = 0
    private let maxPendingInferences  = 1

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialiser
    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        do {
            self.model = try VL1004(configuration: config)
            print("✅ VL1004 Model Loaded Successfully (96k Input)")
        } catch {
            print("❌ Model Load Error: \(error)")
        }
    }

    // MARK: - Engine Lifecycle & Setup (RESTORED & FIXED)
    func startRecording() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            guard granted else {
                print("❌ Microphone permission denied by user.")
                DispatchQueue.main.async { self?.currentStatus = "Mic Permission Denied" }
                return
            }
            self?.setupAndStartEngine()
        }
    }

    private func setupAndStartEngine() {
        let session = AVAudioSession.sharedInstance()
        do {
            // 🚨 THE FIXES:
            // 1. Switched to .record (If you MUST play audio while diarizing, use .playAndRecord but REMOVE .defaultToSpeaker)
            try session.setCategory(.record, mode: .measurement, options: [.allowBluetoothHFP])
            
            // 2. 50ms is generally much safer for CoreML mic taps than 100ms
            try session.setPreferredIOBufferDuration(0.05)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ AVAudioSession activated in .record / .measurement mode")
        } catch {
            print("❌ Failed to set up audio session: \(error)")
            return
        }

        let inputNode = audioEngine.inputNode
        
        // 🚨 3. THE SILVER BULLET: Explicitly tell the engine to keep Voice Processing OFF
        if #available(iOS 13.0, *) {
            do {
                try inputNode.setVoiceProcessingEnabled(false)
                print("✅ Voice Processing explicitly disabled.")
            } catch {
                print("⚠️ Could not disable voice processing: \(error)")
            }
        }

        let hardwareFormat = inputNode.outputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!

        inputNode.removeTap(onBus: 0)
        
        // 🚨 4. Use 1024 or 8192. VPIO hates 4096 and often throws boundary mismatches.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hardwareFormat) { [weak self] (buffer, time) in
            self?.handleAudio(buffer: buffer, targetFormat: targetFormat)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRunning = true
                self.currentStatus = "Listening..."
            }
            print("✅ AVAudioEngine Started Successfully")
        } catch {
            print("❌ Engine start error: \(error)")
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        DispatchQueue.main.async {
            self.isRunning = false
            self.currentStatus = "Ready"
        }
        print("🛑 AVAudioEngine Stopped")
    }

    // MARK: - Enrollment & Configuration
    func enrollUser(completion: @escaping (Bool) -> Void) {
        print("Starting Enrollment for User (ID: 0)")
        self.isEnrolling = true
        self.enrollmentCompletion = completion
        self.collectedSamples.removeAll()
        self.speakerProfiles.removeAll()
        self.speakerNames.removeAll()
        self.lastMatchedSpeakerID = nil
        self.unknownFrameCount = 0
    }

    func setUserName(_ name: String) {
        speakerNames[0] = name
    }

    // MARK: - Audio Ingestion
    public func handleAudio(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        if soundAnalyzer == nil { setupSoundAnalyzer(format: buffer.format) }
        let framePos = analysisFrame
        analysisFrame += AVAudioFramePosition(buffer.frameLength)
        let bufferCopy = buffer
        analysisQueue.async { [weak self] in
            self?.soundAnalyzer?.analyze(bufferCopy, atAudioFramePosition: framePos)
        }

        guard let converter = getConverter(from: buffer.format, to: targetFormat) else { return }

        let ratio    = Float(targetFormat.sampleRate) / Float(buffer.format.sampleRate)
        let capacity = UInt32(Float(buffer.frameLength) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var error: NSError? = nil
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let channelData = outputBuffer.floatChannelData {
            var samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(outputBuffer.frameLength)))
            
            // SIGNAL NORMALIZATION: Ensures volume consistency for strict thresholding
            normalizeAudioSignal(&samples)
            
            DispatchQueue.main.async {
                self.processSamples(samples)
            }
        }
    }

    private func normalizeAudioSignal(_ samples: inout [Float]) {
        var maxAmp: Float = 0
        vDSP_maxv(samples, 1, &maxAmp, vDSP_Length(samples.count))
        if maxAmp > 0 {
            var factor = 1.0 / maxAmp
            vDSP_vsmul(samples, 1, &factor, &samples, 1, vDSP_Length(samples.count))
        }
    }

    private func getConverter(from input: AVAudioFormat, to output: AVAudioFormat) -> AVAudioConverter? {
        if audioConverter == nil || audioConverter?.inputFormat != input {
            audioConverter = AVAudioConverter(from: input, to: output)
        }
        return audioConverter
    }

    // MARK: - Processing Logic
    private func processSamples(_ samples: [Float]) {
        if speechGate.isActive {
            collectedSamples.append(contentsOf: samples)
        }
        
        guard collectedSamples.count >= requiredSamples else { return }

        let chunk = Array(collectedSamples.prefix(requiredSamples))
        collectedSamples.removeFirst(stride)

        scheduleInference(on: chunk)
    }

    // MARK: - Inference Scheduling
    private func scheduleInference(on samples: [Float]) {
        guard pendingInferenceCount <= maxPendingInferences else { return }
        pendingInferenceCount += 1

        inferenceQueue.async { [weak self] in
            defer {
                DispatchQueue.main.async { self?.pendingInferenceCount -= 1 }
            }
            self?.runInference(on: samples)
        }
    }

    private func runInference(on samples: [Float]) {
        guard let model = model else { return }

        guard let inputMultiArray = try? MLMultiArray(shape: [1, NSNumber(value: requiredSamples)], dataType: .float32) else { return }
        for (i, sample) in samples.enumerated() {
            inputMultiArray[i] = NSNumber(value: sample)
        }

        do {
            let startTime  = CFAbsoluteTimeGetCurrent()
            let prediction = try model.prediction(audio: inputMultiArray)
            let _ = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

            let rawEmbedding = self.extractVector(from: prediction.embedding)
            // print("⚡️ Inference: \(String(format: "%.1f", elapsed))ms") // Uncomment to debug inference speed

            DispatchQueue.main.async {
                self.processEmbedding(rawEmbedding)
            }
        } catch {
            print("❌ Inference Error: \(error)")
        }
    }

    // MARK: - Core Diarization
    private func processEmbedding(_ vector: [Float]) {
        let normVector = normalize(vector)

        if isEnrolling {
            print("✅ Enrollment Complete. ID 0 Saved as IMMUTABLE ANCHOR.")
            speakerProfiles[0] = normVector
            if speakerNames[0] == nil { speakerNames[0] = "Me" }
            isEnrolling = false
            enrollmentCompletion?(true)
            enrollmentCompletion = nil
            return
        }

        if speakerProfiles.isEmpty {
            let newID = createNewSpeaker(with: normVector)
            lastMatchedSpeakerID = newID
            return
        }

        var scoredSpeakers: [(id: Int, score: Float, baseScore: Float)] = []
        for (id, profile) in speakerProfiles {
            let baseScore = cosineSim(normVector, profile)
            var adjustedScore = baseScore
            
            // 1. HOME-FIELD ADVANTAGE
            if id == 0 { adjustedScore += 0.02 }
            
            // 2. TEMPORAL CONTINUITY
            if id == lastMatchedSpeakerID { adjustedScore += 0.04 }
            
            // 3. ⭐️ SCORE CAPPING: Prevent math from exceeding 100%
            adjustedScore = min(adjustedScore, 1.0)
            
            scoredSpeakers.append((id: id, score: adjustedScore, baseScore: baseScore))
        }

        scoredSpeakers.sort { $0.score > $1.score }

        let bestID    = scoredSpeakers[0].id
        let maxScore  = scoredSpeakers[0].score
        let rawScore  = scoredSpeakers[0].baseScore // Use UNBOOSTED score for learning!

        if maxScore >= matchThreshold {
            // 1. STRICT MATCH
            unknownFrameCount = 0
            lastMatchedSpeakerID = bestID
            
            print("🎯 Match: Speaker \(bestID) (\(String(format: "%.0f%%", maxScore * 100)))")
            self.confidence = String(format: "%.0f%%", maxScore * 100)
            
            // ⭐️ THE ULTIMATE FIX:
            // - bestID != 0 ensures "Me" is NEVER overwritten by trailer noise.
            // - rawScore > learningThreshold (0.85) ensures guests are updated only from CLEAN audio.
            if bestID != 0 && rawScore > learningThreshold {
                print("🧠 Clean audio detected. Updating profile for Speaker \(bestID).")
                updateProfile(id: bestID, vector: normVector)
            }
            
            addToHistory(vector: normVector, id: bestID, score: maxScore)
            commitVote(for: bestID)
            
        } else if maxScore < deadzoneThreshold {
            // 2. BRAND NEW VOICE
            unknownFrameCount += 1
            
            if unknownFrameCount >= probationLimit {
                print("👽 [NEW VOICE] Persistent unknown signature. Creating New Speaker!")
                let newID = createNewSpeaker(with: normVector)
                
                lastMatchedSpeakerID = newID
                addToHistory(vector: normVector, id: newID, score: 1.0)
                commitVote(for: newID)
                
                unknownFrameCount = 0
            } else {
                print("🚧 Unknown voice detected. Probation: \(unknownFrameCount)/\(probationLimit)")
            }
            
        } else {
            // 3. THE DEADZONE
            unknownFrameCount = 0
            print("🌫 Noisy/Transition Frame (Score \(String(format: "%.2f", maxScore))). Ignored.")
        }
    }

    // MARK: - Frame Voting
    private func commitVote(for speakerID: Int) {
        if speakerID == leadingVoteID {
            voteCount[speakerID, default: 0] += 1
        } else {
            voteCount.removeAll()
            leadingVoteID = speakerID
            voteCount[speakerID] = 1
        }

        if let count = voteCount[speakerID], count >= votingThreshold {
            if currentSpeakerID != speakerID {
                print("🗳 Vote Threshold Met: Committing Speaker \(speakerID)")
            }
            currentSpeakerID = speakerID
            voteCount[speakerID] = votingThreshold
        }
    }

    // MARK: - Adaptive History Management
    private func addToHistory(vector: [Float], id: Int, score: Float) {
        let event = DiarizationEvent(
            timestamp:       Date(),
            vector:          vector,
            assignedSpeakerID: id,
            confidence:      score,
            locationTag:     self.currentLocation
        )
        segmentHistory.append(event)
        if segmentHistory.count > 500 {
            segmentHistory.removeFirst()
        }
    }

    // MARK: - Retroactive Correction (Time Machine)
    func applyRetroactiveCorrection(forEventID eventID: UUID, newName: String) {
        guard let index = segmentHistory.firstIndex(where: { $0.id == eventID }) else { return }
        let ghostID       = segmentHistory[index].assignedSpeakerID
        let mistakeVector = segmentHistory[index].vector
        let mistakeContext = segmentHistory[index].locationTag

        print("⏳ Time Machine: User says Event \(eventID) (ID \(ghostID)) is actually '\(newName)'")

        var targetID: Int = -1

        if let existingID = speakerNames.first(where: { $0.value == newName })?.key {
            targetID = existingID
        } else {
            if ghostID != 0 {
                speakerNames[ghostID] = newName
                print("Renamed ID \(ghostID) to \(newName). No merge needed.")
                self.objectWillChange.send()
                return
            }
            let newID = (speakerProfiles.keys.max() ?? 0) + 1
            speakerProfiles[newID] = mistakeVector
            speakerNames[newID] = newName
            targetID = newID
        }

        var mergeCount  = 0
        var rippleCount = 0

        updateProfile(id: targetID, vector: mistakeVector)

        guard let targetProfile = speakerProfiles[targetID] else { return }

        for i in 0..<segmentHistory.count {
            let event = segmentHistory[i]

            // Pass 1: Hard Merge of Ghost ID
            if event.assignedSpeakerID == ghostID && ghostID != targetID {
                segmentHistory[i].assignedSpeakerID = targetID
                segmentHistory[i].confidence        = 1.0
                updateProfile(id: targetID, vector: event.vector)
                mergeCount += 1
                continue
            }

            // Pass 2: Soft Ripple with Context Weighting
            if event.assignedSpeakerID != 0
                && event.assignedSpeakerID != targetID
                && event.assignedSpeakerID != ghostID {

                var score = cosineSim(event.vector, targetProfile)
                if let evLoc = event.locationTag, let mistLoc = mistakeContext, evLoc == mistLoc {
                    score += 0.10
                }

                if score > 0.75 && score > (event.confidence + 0.05) {
                    print("✨ Magic: Found a missed segment at index \(i) (Score: \(score))")
                    segmentHistory[i].assignedSpeakerID = targetID
                    segmentHistory[i].confidence        = score
                    rippleCount += 1
                }
            }
        }

        if ghostID != targetID {
            speakerProfiles.removeValue(forKey: ghostID)
            speakerNames.removeValue(forKey: ghostID)
        }

        self.objectWillChange.send()
        print("📊 Time Machine Report: Merged \(mergeCount) segments. Discovered \(rippleCount) context-verified matches.")
    }

    // MARK: - Profile Helpers
    @discardableResult
    private func createNewSpeaker(with vector: [Float]) -> Int {
        var newID = 1
        if let maxKey = speakerProfiles.keys.max() {
            newID = maxKey + 1
        }
        if newID == 0 { newID = 1 }

        print("👤 New Speaker Detected: Assigned ID \(newID)")
        self.speakerProfiles[newID] = vector
        self.confidence            = "100%"
        return newID
    }

    private func updateProfile(id: Int, vector: [Float]) {
        if let oldProfile = speakerProfiles[id] {
            speakerProfiles[id] = applyRollingAvg(old: oldProfile, new: vector)
        } else {
            speakerProfiles[id] = vector
        }
    }

    // MARK: - Math Utilities
    private func applyRollingAvg(old: [Float], new: [Float]) -> [Float] {
        var result = [Float](repeating: 0, count: old.count)
        var fOld   = 1.0 - learningRate
        var fNew   = learningRate
        vDSP_vsmul(old, 1, &fOld, &result, 1, vDSP_Length(old.count))
        vDSP_vsma (new, 1, &fNew, result, 1, &result, 1, vDSP_Length(old.count))
        return normalize(result)
    }

    func cosineSim(_ v1: [Float], _ v2: [Float]) -> Float {
        var dot: Float = 0
        vDSP_dotpr(v1, 1, v2, 1, &dot, vDSP_Length(v1.count))
        return dot
    }

    func normalize(_ v: [Float]) -> [Float] {
        var norm: Float = 0
        vDSP_svesq(v, 1, &norm, vDSP_Length(v.count))
        let mag = sqrt(norm) + 1e-9
        var res = [Float](repeating: 0, count: v.count)
        vDSP_vsdiv(v, 1, [mag], &res, 1, vDSP_Length(v.count))
        return res
    }

    func extractVector(from multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        let ptr   = multiArray.dataPointer.bindMemory(to: Float.self, capacity: count)
        return Array(UnsafeBufferPointer(start: ptr, count: count))
    }

    // MARK: - SoundAnalysis Setup
    private func setupSoundAnalyzer(format: AVAudioFormat) {
        let analyzer = SNAudioStreamAnalyzer(format: format)
        do {
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            request.windowDuration = CMTimeMakeWithSeconds(0.5, preferredTimescale: 44_100)
            request.overlapFactor  = 0.75
            try analyzer.add(request, withObserver: speechGate)
            soundAnalyzer = analyzer
            print("🔊 [SoundAnalysis] Speech gate active (window=0.5s, overlap=75%)")
        } catch {
            print("⚠️ [SoundAnalysis] Could not set up speech gate: \(error). Inference will run ungated.")
        }
    }
}

// MARK: - SpeechActivityGate

private class SpeechActivityGate: NSObject, SNResultsObserving {

    private let speechLabels: Set<String> = [
        "speech", "singing", "shout", "laughter",
        "crying_sobbing", "crowd"
    ]

    private var _isActive: Bool = true
    private let lock = NSLock()

    var isActive: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isActive
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let top    = result.classifications.first else { return }

        let active = speechLabels.contains(top.identifier) && top.confidence > 0.15
        lock.lock()
        _isActive = active
        lock.unlock()
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("❌ [SpeechGate] Analysis error: \(error)")
        lock.lock(); _isActive = true; lock.unlock()
    }
}
