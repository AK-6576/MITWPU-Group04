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

/// A data model representing a specific voice segment identified by the diarizer.
struct DiarizationEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let vector: [Float]
    var assignedSpeakerID: Int
    var confidence: Float
    let locationTag: String?
}

/// The core engine responsible for real-time speaker diarization and embedding extraction on-device.
/// Optimized for iPhone 16 (A18) using the Apple Neural Engine (ANE).
class AudioDiarizer: ObservableObject {
    
    // MARK: - Core Components
    private let audioEngine = AVAudioEngine()
    private var audioConverter: AVAudioConverter?
    private var model: VL1004?
    
    // MARK: - Sliding Window Configuration
    private let requiredSamples = 96000  // 6.0 seconds @ 16kHz
    private let stride          = 4800   // 300 ms sliding window for real-time responsiveness
    private var collectedSamples: [Float] = []
    
    // MARK: - Accuracy & Learning Parameters
    private let similarityThreshold: Float = 0.72  // Minimum cosine similarity for matching
    private let learningThreshold:   Float = 0.88  // Threshold for updating a speaker's memory bank
    private let learningRate:        Float = 0.03  // Weight of new vectors in the rolling average
    
    // MARK: - Voice Activity Detection (VAD)
    private var adaptiveVadThreshold: Float = -45.0 // Initial baseline (adapts to room noise)
    private var noiseFloorBuffer: [Float] = []
    private let noiseFloorLimit = 10
    private var isSilent: Bool = true
    
    // MARK: - Diarization Logic & Voting
    private let votingThreshold = 3
    private var voteCount: [Int: Int] = [:]       // Tracker for consecutive speaker detections
    private var leadingVoteID: Int?               // Speaker ID currently accumulating votes
    
    // MARK: - Topographic Memory Bank (3D Clustering)
    private var speakerClusterMemory: [Int: [[Float]]] = [:]
    private let maxClusterSize = 35               // Max fingerprints stored per speaker profile
    
    // MARK: - Published State (UI Linked)
    @Published var speakerProfiles: [Int: [Float]] = [:]
    @Published var speakerNames:    [Int: String] = [:]
    @Published var currentStatus:   String = "Ready"
    @Published var confidence:      String = "--"
    @Published var isRunning               = false
    @Published var currentSpeakerID: Int?  = nil
    @Published var segmentHistory: [DiarizationEvent] = []
    
    public var currentLocation: String? = nil
    
    // MARK: - Concurrency Control
    private let audioProcessingQueue = DispatchQueue(label: "com.mitwpu.audiodiarizer.processing", qos: .userInitiated)
    private let inferenceQueue       = DispatchQueue(label: "com.mitwpu.audiodiarizer.inference", qos: .userInitiated)
    private var pendingInferenceCount = 0
    private let maxPendingInferences  = 1
    private var cancellables = Set<AnyCancellable>()
    
    private var isEnrolling = false
    private var enrollmentCompletion: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        do {
            self.model = try VL1004(configuration: config)
            print("VL1004 Model Loaded Successfully (ANE Optimized)")
        } catch {
            print("Model Load Error: \(error)")
        }
    }
    
    // MARK: - Public API (Enrollment & Recording)
    
    /// Prepares the engine to record the primary user's voice profile (ID 0).
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
    
    // MARK: - Audio Pipeline (Ingestion)
    
    /// Entry point for incoming audio buffers. Handles format conversion and background dispatch.
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
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(outputBuffer.frameLength)))
            audioProcessingQueue.async {
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
    
    // MARK: - Signal Processing (VAD & Chunking)
    
    private func processSamples(_ samples: [Float]) {
        // Calculate frame energy (RMS)
        var frameRms: Float = 0
        vDSP_rmsqv(samples, 1, &frameRms, vDSP_Length(samples.count))
        let frameDb = 20 * log10(max(frameRms, 1e-8))
        
        // Adaptive Noise Floor Tracking
        updateNoiseFloor(frameDb)
        
        let wasSilent = self.isSilent
        self.isSilent = (frameDb < adaptiveVadThreshold + 8.0) // Audio must be 8dB above floor to be 'speech'
        
        if collectedSamples.isEmpty {
            collectedSamples.reserveCapacity(requiredSamples + stride)
        }
        
        collectedSamples.append(contentsOf: samples)
        
        // Window verification
        guard collectedSamples.count >= requiredSamples else { return }
        
        let chunk = Array(collectedSamples.prefix(requiredSamples))
        
        // Array shift optimization (sliding window)
        let removeCount    = stride
        let remainingCount = collectedSamples.count - removeCount
        if remainingCount > 0 {
            collectedSamples.withUnsafeMutableBufferPointer { ptr in
                guard let base = ptr.baseAddress else { return }
                memmove(base, base.advanced(by: removeCount), remainingCount * MemoryLayout<Float>.size)
            }
            collectedSamples.removeLast(removeCount)
        } else {
            collectedSamples.removeAll(keepingCapacity: true)
        }
        
        // Inference gatekeeper
        if !isSilent || !wasSilent {
            scheduleInference(on: chunk)
        }
    }
    
    // MARK: - CoreML Inference Pipeline
    
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
        guard let inputBuffer = try? MLMultiArray(shape: [1, NSNumber(value: requiredSamples)], dataType: .float32) else { return }
        
        // Zero-copy Raw Memory Transfer
        samples.withUnsafeBufferPointer { buffer in
            if let address = buffer.baseAddress {
                memcpy(inputBuffer.dataPointer, address, requiredSamples * MemoryLayout<Float>.size)
            }
        }
        
        do {
            let startTime  = CFAbsoluteTimeGetCurrent()
            let prediction = try model.prediction(audio: inputBuffer)
            let elapsed    = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            let rawEmbedding = self.extractVector(from: prediction.embedding)
            print("Diarization Inference: \(String(format: "%.1f", elapsed))ms")
            
            self.processEmbedding(rawEmbedding)
        } catch {
            print("Inference Error: \(error)")
        }
    }
    
    // MARK: - Diarization Reasoning (The "Brain")
    
    private func processEmbedding(_ vector: [Float]) {
        let normVector = normalize(vector)
        
        // Enrollment bypass
        if isEnrolling {
            DispatchQueue.main.async {
                self.speakerProfiles[0] = normVector
                self.speakerClusterMemory[0] = [normVector]
                if self.speakerNames[0] == nil { self.speakerNames[0] = "Me" }
                self.isEnrolling = false
                self.enrollmentCompletion?(true)
                print("User Enrolled Successfully.")
            }
            return
        }
        
        // Initialize first speaker if bank is empty
        if speakerClusterMemory.isEmpty {
            DispatchQueue.main.async { self.createNewSpeaker(with: normVector) }
            return
        }
        
        // Vectorized Clustering Search (Topography Search)
        var bestID: Int = -1
        var maxScore: Float = -1.0
        var debugString = "Scores: "
        
        for (id, cluster) in speakerClusterMemory {
            let score = searchClusterVectorized(vector: normVector, cluster: cluster)
            let name  = speakerNames[id] ?? "Speaker \(id)"
            debugString += "\(name): \(String(format: "%.3f", score)) | "
            
            if score > maxScore {
                maxScore = score
                bestID   = id
            }
        }
        
        // Consensus Logic
        if maxScore > similarityThreshold {
            updateProfile(id: bestID, vector: normVector, score: maxScore)
            DispatchQueue.main.async {
                self.confidence = String(format: "%.0f%%", maxScore * 100)
                self.addToHistory(vector: normVector, id: bestID, score: maxScore)
                self.commitVote(for: bestID)
            }
        } else {
            DispatchQueue.main.async {
                let newID = self.createNewSpeaker(with: normVector)
                self.addToHistory(vector: normVector, id: newID, score: 1.0)
                self.commitVote(for: newID)
            }
        }
    }
    
    // MARK: - Voting & Commitment Architecture
    
    private func commitVote(for speakerID: Int) {
        if speakerID == leadingVoteID {
            voteCount[speakerID, default: 0] += 1
        } else {
            voteCount.removeAll()
            leadingVoteID = speakerID
            voteCount[speakerID] = 1
        }
        
        if let count = voteCount[speakerID], count >= votingThreshold {
            currentSpeakerID = speakerID
            voteCount[speakerID] = votingThreshold // Cap at threshold for stability
        }
    }
    
    func forceCommitLeadingVote() {
        if let leader = self.leadingVoteID, self.currentSpeakerID != leader {
            print("Force-committing speaker \(leader) due to conversation pause.")
            self.currentSpeakerID = leader
            self.voteCount[leader] = self.votingThreshold
        }
    }
    
    // MARK: - History Management
    
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
    
    // MARK: - "Time Machine" Historical Corrections
    
    /// Asynchronously corrects the speaker identity of a past event and propagates the correction.
    func applyRetroactiveCorrection(forEventID eventID: UUID, newName: String) {
        Task {
            guard let index = segmentHistory.firstIndex(where: { $0.id == eventID }) else { return }
            let ghostID       = segmentHistory[index].assignedSpeakerID
            let mistakeVector = segmentHistory[index].vector
            let mistakeContext = segmentHistory[index].locationTag
            
            var targetID: Int = -1
            
            if let existingID = speakerNames.first(where: { $0.value == newName })?.key {
                targetID = existingID
            } else {
                if ghostID != 0 {
                    DispatchQueue.main.async {
                        self.speakerNames[ghostID] = newName
                        self.objectWillChange.send()
                    }
                    return
                }
                let newID = (speakerProfiles.keys.max() ?? 0) + 1
                DispatchQueue.main.async {
                    self.speakerProfiles[newID] = mistakeVector
                    self.speakerClusterMemory[newID] = [mistakeVector]
                    self.speakerNames[newID] = newName
                }
                targetID = newID
            }
            
            updateProfile(id: targetID, vector: mistakeVector, score: 1.0, force: true)
            guard let targetProfile = speakerProfiles[targetID] else { return }
            
            for i in 0..<segmentHistory.count {
                let event = segmentHistory[i]
                
                // Pass 1: Direct Merge of Ghost Identity
                if event.assignedSpeakerID == ghostID && ghostID != targetID {
                    DispatchQueue.main.async {
                        self.segmentHistory[i].assignedSpeakerID = targetID
                        self.segmentHistory[i].confidence        = 1.0
                    }
                    updateProfile(id: targetID, vector: event.vector, score: 1.0, force: true)
                    continue
                }
                
                // Pass 2: Context-Aware Soft Matching
                if event.assignedSpeakerID != 0 && event.assignedSpeakerID != targetID {
                    var score = cosineSim(event.vector, targetProfile)
                    if let evLoc = event.locationTag, let mistLoc = mistakeContext, evLoc == mistLoc { score += 0.10 }
                    
                    if score > 0.75 && score > (event.confidence + 0.05) {
                        DispatchQueue.main.async {
                            self.segmentHistory[i].assignedSpeakerID = targetID
                            self.segmentHistory[i].confidence        = score
                        }
                    }
                }
            }
            
            if ghostID != targetID {
                DispatchQueue.main.async {
                    self.speakerProfiles.removeValue(forKey: ghostID)
                    self.speakerClusterMemory.removeValue(forKey: ghostID)
                    self.speakerNames.removeValue(forKey: ghostID)
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    // MARK: - Mathematical Utilities (Accelerate Optimization)
    
    private func searchClusterVectorized(vector: [Float], cluster: [[Float]]) -> Float {
        var maxScore: Float = -1.0
        for clusterVector in cluster {
            var dot: Float = 0
            vDSP_dotpr(vector, 1, clusterVector, 1, &dot, vDSP_Length(vector.count))
            if dot > maxScore { maxScore = dot }
        }
        return maxScore
    }
    
    private func applyRollingAvg(old: [Float], new: [Float]) -> [Float] {
        var result = [Float](repeating: 0, count: old.count)
        var fOld = 1.0 - learningRate
        var fNew = learningRate
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
    
    /// Converts an MLMultiArray embedding into a standard Swift Float array.
    func extractVector(from multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        let ptr   = multiArray.dataPointer.bindMemory(to: Float.self, capacity: count)
        return Array(UnsafeBufferPointer(start: ptr, count: count))
    }
    
    @discardableResult
    private func createNewSpeaker(with vector: [Float]) -> Int {
        let newID = (speakerProfiles.keys.max() ?? 0) + 1
        speakerProfiles[newID] = vector
        speakerClusterMemory[newID] = [vector]
        self.confidence            = "100%"
        return newID
    }
    
    private func updateProfile(id: Int, vector: [Float], score: Float, force: Bool = false) {
        if id == 0 && !force { return }
        if force || score > learningThreshold {
            if speakerClusterMemory[id] == nil { speakerClusterMemory[id] = [] }
            speakerClusterMemory[id]?.append(vector)
            if (speakerClusterMemory[id]?.count ?? 0) > maxClusterSize { speakerClusterMemory[id]?.removeFirst() }
            
            if let oldProfile = speakerProfiles[id] {
                speakerProfiles[id] = applyRollingAvg(old: oldProfile, new: vector)
            } else {
                speakerProfiles[id] = vector
            }
        }
    }
    
    private func updateNoiseFloor(_ currentDb: Float) {
        noiseFloorBuffer.append(currentDb)
        if noiseFloorBuffer.count > noiseFloorLimit { noiseFloorBuffer.removeFirst() }
        let avgFloor = noiseFloorBuffer.reduce(0, +) / Float(noiseFloorBuffer.count)
        adaptiveVadThreshold = (adaptiveVadThreshold * 0.95) + (avgFloor * 0.05)
    }
}
