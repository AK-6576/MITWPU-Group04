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
    private let requiredSamples = 96000
    private let stride          = 4800
    private var collectedSamples: [Float] = []

    // MARK: - Accuracy Parameters
    // Reset to robust levels since we are now using Dense Speech Accumulation
    private let similarityThreshold: Float = 0.90
    private let learningThreshold:   Float = 0.92
    private let learningRate:        Float = 0.05
    
    // Switch Penalty removed for absolute discrimination accuracy
    private let switchingPenalty:    Float = 0.0

    // MARK: - Voice Activity Detection
    private let vadThresholdDB: Float = -35.0
    private var isSilent: Bool = true

    // MARK: - Pause-Aware Window Management
    //
    // When a speaker pauses mid-session, the 6s sliding window fills with
    // silence. The next speech chunk is then a mixed window (silence + speech)
    // whose embedding drifts far from the clean-speech enrollment vector,
    // causing the enrolled speaker to score below threshold and be assigned
    // a new ghost ID.
    //
    // Fix: track consecutive silent frames. Once silence exceeds
    // pauseFlushThreshold frames (~1.5s), discard the collected sample
    // buffer entirely so the NEXT speech starts a fresh, clean window
    // rather than one contaminated by the preceding silence.
    private var consecutiveSilentFrames: Int = 0
    private let pauseFlushThreshold:     Int = 5  // Fast flush (~0.15s) to separate speakers

    // MARK: - Frame Voting & Smoothing
    private let votingThreshold = 3  // Increased from 2 for better stability
    private var voteCount:    [Int: Int] = [:]
    private var leadingVoteID: Int?
    
    // Smoothing: average embeddings of last 3 windows to reduce jitter
    private var recentEmbeddings: [[Float]] = []
    private let smoothingWindowSize = 3

    // MARK: - Speaker Cluster Memory
    // FIX 3: maxClusterSize kept at 35, but eviction is now reservoir-based
    // (random slot replacement) instead of FIFO removeFirst().
    // Slot 0 in each cluster is always the enrollment/first-seen vector and
    // is never evicted, so the anchor reference survives long sessions.
    var speakerClusterMemory: [Int: [[Float]]] = [:]
    private let maxClusterSize = 35

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
    private let inferenceQueue = DispatchQueue(label: "com.ansd.audiodiarizer.inference",
                                               qos: .userInitiated)
    private var pendingInferenceCount = 0
    private let maxPendingInferences  = 1

    // MARK: - SoundAnalysis Speech Gate
    private let speechGate     = SpeechActivityGate()
    private var soundAnalyzer:  SNAudioStreamAnalyzer?
    private let analysisQueue  = DispatchQueue(label: "com.ansd.soundanalysis", qos: .userInitiated)
    private var analysisFrame:  AVAudioFramePosition = 0

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialiser

    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        do {
            self.model = try VL1004(configuration: config)
            print("VL1004 Model Loaded Successfully (96k Input)")
        } catch {
            print("Model Load Error: \(error)")
        }
    }

    // MARK: - Enrollment & Configuration

    func enrollUser(completion: @escaping (Bool) -> Void) {
        print("Starting Enrollment for User (ID: 0)")
        self.isEnrolling = true
        self.enrollmentCompletion = completion
        self.collectedSamples.removeAll()
        self.speakerProfiles.removeAll()
        self.speakerClusterMemory.removeAll()
        self.speakerNames.removeAll()
    }

    func setUserName(_ name: String) {
        speakerNames[0] = name
    }

    // MARK: - Audio Ingestion

    func handleAudio(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
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
            let samples = Array(UnsafeBufferPointer(start: channelData[0],
                                                    count: Int(outputBuffer.frameLength)))
            DispatchQueue.main.async {
                self.processSamples(samples)
            }
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
        var frameRms: Float = 0
        vDSP_rmsqv(samples, 1, &frameRms, vDSP_Length(samples.count))
        let frameDb = 20 * log10(max(frameRms, 1e-8))
        self.isSilent = (frameDb < vadThresholdDB)

        // --- TOP-NOTCH: Dense Speech Accumulation ---
        // Only store samples if they are active speech (voice-active).
        // This ensures the 6s window is always "packed" with voice energy,
        // which we've proven raises your similarity score to >95%.
        if !isSilent && speechGate.isActive {
            collectedSamples.append(contentsOf: samples)
            consecutiveSilentFrames = 0
        } else {
            consecutiveSilentFrames += 1
            // If silent for too long (e.g. 10s), flush to prevent "stale" voice contamination
            if consecutiveSilentFrames > pauseFlushThreshold {
                collectedSamples.removeAll(keepingCapacity: true)
            }
        }
        
        // Wait until we have exactly 6 seconds of voice
        guard collectedSamples.count >= requiredSamples else { return }
        
        let chunk = Array(collectedSamples.prefix(requiredSamples))
        
        // Slide the window
        let removeCount = stride
        if collectedSamples.count >= removeCount {
            collectedSamples.removeFirst(removeCount)
        } else {
            collectedSamples.removeAll(keepingCapacity: true)
        }

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

        // 1. Normalize RMS for consistent model input
        let normalizedSamples = DiarizationUtils.normalizeAudio(samples)

        guard let inputMultiArray = try? MLMultiArray(shape: [1, NSNumber(value: requiredSamples)],
                                                      dataType: .float32) else { return }
        for (i, sample) in normalizedSamples.enumerated() {
            inputMultiArray[i] = NSNumber(value: sample)
        }

        do {
            let startTime  = CFAbsoluteTimeGetCurrent()
            let prediction = try model.prediction(audio: inputMultiArray)
            let elapsed    = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

            let rawEmbedding = self.extractVector(from: prediction.embedding)
            print("Inference: \(String(format: "%.1f", elapsed))ms")

            DispatchQueue.main.async {
                self.processEmbedding(rawEmbedding)
            }
        } catch {
            print("Error: Inference Error: \(error)")
        }
    }

    // MARK: - Core Diarization
    
    private func processEmbedding(_ vector: [Float]) {
        let normVector = DiarizationUtils.l2Normalize(vector)

        if isEnrolling {
            if !isSilent && speechGate.isActive {
                print("Enrollment Complete. ID 0 Saved (Gated).")
                speakerProfiles[0] = normVector
                speakerClusterMemory[0] = [normVector]
                if speakerNames[0] == nil { speakerNames[0] = "Me" }
                isEnrolling = false
                enrollmentCompletion?(true)
                enrollmentCompletion = nil
            }
            return
        }

        if speakerClusterMemory.isEmpty {
            createNewSpeaker(with: normVector)
            return
        }
        
        // --- TOP-NOTCH: Temporal Embedding Smoothing ---
        // Scoring the average of recent frames prevents "jitter" from short artifacts.
        recentEmbeddings.append(normVector)
        if recentEmbeddings.count > smoothingWindowSize {
            recentEmbeddings.removeFirst()
        }
        
        var scoringVector = normVector
        if recentEmbeddings.count > 1 {
            var sum = [Float](repeating: 0, count: normVector.count)
            for vec in recentEmbeddings {
                vDSP_vadd(sum, 1, vec, 1, &sum, 1, vDSP_Length(sum.count))
            }
            scoringVector = DiarizationUtils.l2Normalize(sum)
        }

        // --- Centroid-based scoring ---
        var scoredSpeakers: [(id: Int, score: Float)] = []
        var debugString = "Scores: "

        for (id, cluster) in speakerClusterMemory {
            guard !cluster.isEmpty else { continue }

            // Compute cluster centroid
            var centroid = [Float](repeating: 0, count: cluster[0].count)
            for vec in cluster {
                vDSP_vadd(centroid, 1, vec, 1, &centroid, 1, vDSP_Length(centroid.count))
            }
            centroid = DiarizationUtils.l2Normalize(centroid)

            var score = DiarizationUtils.cosineSimilarity(scoringVector, centroid)
            
            // --- TOP-NOTCH: Hysteresis (Switching Penalty) ---
            if id == currentSpeakerID {
                score += switchingPenalty
            }

            let name  = speakerNames[id] ?? "Spk\(id)"
            debugString += "\(name): \(String(format: "%.3f", score)) | "
            scoredSpeakers.append((id: id, score: score))
        }

        print(debugString)

        // Sort descending by score
        scoredSpeakers.sort { $0.score > $1.score }

        let bestID      = scoredSpeakers[0].id
        let maxScore    = scoredSpeakers[0].score
        let secondScore = scoredSpeakers.count > 1 ? scoredSpeakers[1].score : -1.0
        let margin      = maxScore - secondScore

        if maxScore > similarityThreshold {
            // Margin guard — don't jump unless confident the new speaker is different
            if margin < 0.04 && scoredSpeakers.count > 1 {
                if let current = currentSpeakerID { commitVote(for: current) }
                return
            }

            // Confident match
            print("Match: Speaker \(bestID) (\(String(format: "%.0f%%", maxScore * 100)))")
            self.confidence = String(format: "%.0f%%", maxScore * 100)

            // TOP-NOTCH: Prevent identity drift for the enrolled User (ID 0).
            // We only update profiles for NEW speakers discovered during the session.
            if bestID != 0 {
                updateProfile(id: bestID, vector: normVector, score: maxScore)
            }
            
            addToHistory(vector: normVector, id: bestID, score: maxScore)
            commitVote(for: bestID)

        } else {
            print("[UNKNOWN] (Best: \(String(format: "%.2f", maxScore))) -> Creating New Speaker")
            let newID = createNewSpeaker(with: normVector)
            addToHistory(vector: normVector, id: newID, score: 1.0)
            commitVote(for: newID)
            
            // Reset smoothing on speaker change
            recentEmbeddings.removeAll()
            recentEmbeddings.append(normVector)
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
                print("Vote Threshold Met: Committing Speaker \(speakerID)")
            }
            currentSpeakerID = speakerID
            voteCount[speakerID] = votingThreshold
        }
    }

    // MARK: - Semantic / Pause Forcing

    func forceCommitLeadingVote() {
        if let leader = self.leadingVoteID, self.currentSpeakerID != leader {
            print("Force Committing Leading Vote: Speaker \(leader) due to pause.")
            self.currentSpeakerID = leader
            self.voteCount[leader] = self.votingThreshold
        }
    }

    // MARK: - Adaptive History Management

    private func addToHistory(vector: [Float], id: Int, score: Float) {
        let event = DiarizationEvent(
            timestamp:         Date(),
            vector:            vector,
            assignedSpeakerID: id,
            confidence:        score,
            locationTag:       self.currentLocation
        )
        segmentHistory.append(event)
        if segmentHistory.count > 500 {
            segmentHistory.removeFirst()
        }
    }

    // MARK: - Retroactive Correction (Time Machine)

    func applyRetroactiveCorrection(forEventID eventID: UUID, newName: String) {
        guard let index = segmentHistory.firstIndex(where: { $0.id == eventID }) else { return }
        let ghostID        = segmentHistory[index].assignedSpeakerID
        let mistakeVector  = segmentHistory[index].vector
        let mistakeContext = segmentHistory[index].locationTag

        print("Time Machine: User says Event \(eventID) (ID \(ghostID)) is actually '\(newName)'")

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
            speakerClusterMemory[newID] = [mistakeVector]
            speakerNames[newID] = newName
            targetID = newID
        }

        var mergeCount  = 0
        var rippleCount = 0

        updateProfile(id: targetID, vector: mistakeVector, score: 1.0, force: true)

        guard let targetProfile = speakerProfiles[targetID] else { return }

        for i in 0..<segmentHistory.count {
            let event = segmentHistory[i]

            if event.assignedSpeakerID == ghostID && ghostID != targetID {
                segmentHistory[i].assignedSpeakerID = targetID
                segmentHistory[i].confidence        = 1.0
                updateProfile(id: targetID, vector: event.vector, score: 1.0, force: true)
                mergeCount += 1
                continue
            }

            if event.assignedSpeakerID != 0
                && event.assignedSpeakerID != targetID
                && event.assignedSpeakerID != ghostID {

                var score = cosineSim(event.vector, targetProfile)
                if let evLoc = event.locationTag, let mistLoc = mistakeContext, evLoc == mistLoc {
                    score += 0.10
                }

                if score > 0.75 && score > (event.confidence + 0.05) {
                    print("Magic: Found a missed segment at index \(i) (Score: \(score))")
                    segmentHistory[i].assignedSpeakerID = targetID
                    segmentHistory[i].confidence        = score
                    rippleCount += 1
                }
            }
        }

        if ghostID != targetID {
            speakerProfiles.removeValue(forKey: ghostID)
            speakerClusterMemory.removeValue(forKey: ghostID)
            speakerNames.removeValue(forKey: ghostID)
        }

        self.objectWillChange.send()
        print("Time Machine Report: Merged \(mergeCount) segments. Discovered \(rippleCount) context-verified matches.")
    }

    // MARK: - Profile Helpers

    @discardableResult
    private func createNewSpeaker(with vector: [Float]) -> Int {
        var newID = 1
        if let maxKey = speakerProfiles.keys.max() {
            newID = maxKey + 1
        }
        if newID == 0 { newID = 1 }

        print("New Speaker Detected: Assigned ID \(newID)")
        self.speakerProfiles[newID] = vector
        self.speakerClusterMemory[newID] = [vector]
        self.confidence = "100%"
        return newID
    }

    // FIX 3 — Reservoir eviction replaces FIFO removeFirst().
    //
    // Old behaviour: always evict index 0 (the oldest vector, usually the
    // enrollment frame). After ~35 * 0.3s = ~10 minutes, the enrollment anchor
    // is gone and the cluster drifts freely, causing the enrolled user to be
    // misidentified as a new speaker in long sessions.
    //
    // New behaviour: slot 0 is pinned (never replaced). All subsequent evictions
    // pick a random slot from index 1..maxClusterSize-1. The cluster stays
    // diverse across time while always retaining its founding reference.
    private func updateProfile(id: Int, vector: [Float], score: Float, force: Bool = false) {
        if force || score > learningThreshold {
            if speakerClusterMemory[id] == nil {
                speakerClusterMemory[id] = []
            }

            if (speakerClusterMemory[id]?.count ?? 0) < maxClusterSize {
                // Fill phase: just append until cluster is full
                speakerClusterMemory[id]?.append(vector)
            } else {
                // Reservoir phase: replace a random slot, never slot 0 (enrollment anchor)
                let replaceIdx = Int.random(in: 1..<maxClusterSize)
                speakerClusterMemory[id]?[replaceIdx] = vector
            }

            // Keep centroid profile in sync for downstream components
            if let oldProfile = speakerProfiles[id] {
                speakerProfiles[id] = applyRollingAvg(old: oldProfile, new: vector)
            } else {
                speakerProfiles[id] = vector
            }
        }
    }

    // MARK: - Legacy Cleanup
    // Logic moved to DiarizationUtils.swift. 
    // Kept internal helpers for rolling average only.

    private func applyRollingAvg(old: [Float], new: [Float]) -> [Float] {
        var result = [Float](repeating: 0, count: old.count)
        var fOld   = 1.0 - learningRate
        var fNew   = learningRate
        vDSP_vsmul(old, 1, &fOld, &result, 1, vDSP_Length(old.count))
        vDSP_vsma (new, 1, &fNew, result, 1, &result, 1, vDSP_Length(old.count))
        return DiarizationUtils.l2Normalize(result)
    }

    func cosineSim(_ v1: [Float], _ v2: [Float]) -> Float {
        return DiarizationUtils.cosineSimilarity(v1, v2)
    }

    func normalize(_ v: [Float]) -> [Float] {
        return DiarizationUtils.l2Normalize(v)
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
            print("[SoundAnalysis] Speech gate active (window=0.5s, overlap=75%)")
        } catch {
            print("[SoundAnalysis] Could not set up speech gate: \(error). Inference will run ungated.")
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

        if !active {
            print("[SpeechGate] Blocked non-speech frame: \(top.identifier) (\(String(format: "%.0f%%", top.confidence * 100)))")
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("[SpeechGate] Analysis error: \(error)")
        lock.lock(); _isActive = true; lock.unlock()
    }
}
