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
    //
    // requiredSamples = 96000  →  6 seconds of audio at 16 kHz (model input size, unchanged)
    // stride          = 4800   →  300 ms slide interval at 16 kHz (restored from bad 8000 value)
    //
    private let requiredSamples = 96000
    private let stride          = 4800   // 300 ms — fine-grained sliding window for responsive detection
    private var collectedSamples: [Float] = []

    // MARK: - Accuracy Parameters
    //
    // similarityThreshold: minimum cosine similarity to accept a known speaker match.
    //   Raised from 0.62 → 0.72 to avoid false "new speaker" creation on brief noise.
    //
    // learningThreshold: minimum confidence required before updating a speaker's profile.
    //   Raised from 0.88 → 0.90 so profile drift is gated on very confident frames only.
    //
    // learningRate: weight of new vector when rolling-averaging a profile.
    //   Lowered from 0.05 → 0.03 for slower, more stable profile evolution.
    //
    private let similarityThreshold: Float = 0.72
    private let learningThreshold:   Float = 0.90
    private let learningRate:        Float = 0.03

    // MARK: - Frame Voting
    //
    // A speaker change only commits after votingThreshold consecutive frames agree
    // on the same speaker ID. This prevents single noisy frames from flipping bubbles.
    //
    private let votingThreshold = 3
    private var voteCount:    [Int: Int] = [:]   // speakerID → consecutive frame count
    private var leadingVoteID: Int?               // speaker currently accumulating votes

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
    //
    // Previous implementation used a simple boolean guard that silently dropped inferences.
    // Now we use a serial DispatchQueue so inferences queue up (max depth 1) rather than
    // being discarded entirely, ensuring every acoustic segment gets processed.
    //
    private let inferenceQueue = DispatchQueue(label: "com.ansd.audiodiarizer.inference",
                                               qos: .userInitiated)
    private var pendingInferenceCount = 0        // lightweight counter, accessed only on main
    private let maxPendingInferences  = 1        // at most 1 queued inference at a time

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
        self.speakerNames.removeAll()
    }

    func setUserName(_ name: String) {
        speakerNames[0] = name
    }

    // MARK: - Audio Ingestion

    func handleAudio(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
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
        if collectedSamples.isEmpty {
            collectedSamples.reserveCapacity(requiredSamples + stride)
        }

        collectedSamples.append(contentsOf: samples)

        guard collectedSamples.count >= requiredSamples else { return }

        let chunk = Array(collectedSamples.prefix(requiredSamples))

        // Efficient sliding window array shift using memmove
        let removeCount    = stride
        let remainingCount = collectedSamples.count - removeCount
        if remainingCount > 0 {
            collectedSamples.withUnsafeMutableBufferPointer { ptr in
                guard let base = ptr.baseAddress else { return }
                memmove(base, base.advanced(by: removeCount),
                        remainingCount * MemoryLayout<Float>.size)
            }
            collectedSamples.removeLast(removeCount)
        } else {
            collectedSamples.removeAll(keepingCapacity: true)
        }

        scheduleInference(on: chunk)
    }

    // MARK: - Inference Scheduling
    //
    // Replaces the old `if isInferenceRunning { return }` drop-all guard.
    // We allow at most maxPendingInferences in the queue so stale audio cannot pile up,
    // but we never silently discard the current frame while the queue is idle.
    //
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

        guard let inputMultiArray = try? MLMultiArray(shape: [1, NSNumber(value: requiredSamples)],
                                                      dataType: .float32) else { return }
        for (i, sample) in samples.enumerated() {
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
        let normVector = normalize(vector)

        if isEnrolling {
            print("Enrollment Complete. ID 0 Saved.")
            speakerProfiles[0] = normVector
            if speakerNames[0] == nil { speakerNames[0] = "Me" }
            isEnrolling = false
            enrollmentCompletion?(true)
            enrollmentCompletion = nil
            return
        }

        if speakerProfiles.isEmpty {
            createNewSpeaker(with: normVector)
            return
        }

        var bestID: Int   = -1
        var maxScore: Float = -1.0
        var debugString = "Scores: "

        for (id, profile) in speakerProfiles {
            let score = cosineSim(normVector, profile)
            let name  = speakerNames[id] ?? "Spk\(id)"
            debugString += "\(name): \(String(format: "%.3f", score)) | "

            if score > maxScore {
                maxScore = score
                bestID   = id
            }
        }
        print(debugString)

        if maxScore > similarityThreshold {
            print("Match: Speaker \(bestID) (\(String(format: "%.0f%%", maxScore * 100)))")
            self.confidence = String(format: "%.0f%%", maxScore * 100)

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
        }
    }

    // MARK: - Frame Voting
    //
    // Accumulates consecutive-frame votes for a speaker ID.
    // `currentSpeakerID` (the @Published property consumed by the VC) is only updated
    // after votingThreshold frames in a row agree — preventing noisy single-frame flips.
    //
    private func commitVote(for speakerID: Int) {
        if speakerID == leadingVoteID {
            voteCount[speakerID, default: 0] += 1
        } else {
            // New candidate — reset vote buffer
            voteCount.removeAll()
            leadingVoteID = speakerID
            voteCount[speakerID] = 1
        }

        if let count = voteCount[speakerID], count >= votingThreshold {
            if currentSpeakerID != speakerID {
                print("Vote Threshold Met: Committing Speaker \(speakerID)")
            }
            // Unconditionally assign so the @Published property continuously emits,
            // which tells the QuickCaptioningViewController to flush its transcript buffer.
            currentSpeakerID = speakerID
            
            // Reset so a continued run doesn't permanently lock; 
            // next vote resets cleanly on speaker change.
            voteCount[speakerID] = votingThreshold // hold at threshold
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
            speakerNames[newID] = newName
            targetID = newID
        }

        var mergeCount  = 0
        var rippleCount = 0

        updateProfile(id: targetID, vector: mistakeVector, score: 1.0, force: true)

        guard let targetProfile = speakerProfiles[targetID] else { return }

        for i in 0..<segmentHistory.count {
            let event = segmentHistory[i]

            // Pass 1: Hard Merge of Ghost ID
            if event.assignedSpeakerID == ghostID && ghostID != targetID {
                segmentHistory[i].assignedSpeakerID = targetID
                segmentHistory[i].confidence        = 1.0
                updateProfile(id: targetID, vector: event.vector, score: 1.0, force: true)
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
                    print("Magic: Found a missed segment at index \(i) (Score: \(score))")
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
        self.currentSpeakerID      = newID
        self.confidence            = "100%"

        // Seed the vote buffer so the new speaker is immediately stable
        leadingVoteID = newID
        voteCount     = [newID: votingThreshold]

        return newID
    }

    private func updateProfile(id: Int, vector: [Float], score: Float, force: Bool = false) {
        if id == 0 && !force { return }
        if force || score > learningThreshold, let oldProfile = speakerProfiles[id] {
            speakerProfiles[id] = applyRollingAvg(old: oldProfile, new: vector)
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
}
