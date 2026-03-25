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
    private let requiredSamples = 96000 // 6 seconds @ 16kHz
    private let stride          = 4800  // 300ms slide interval
    private var collectedSamples: [Float] = []

    // MARK: - Core Diarization Parameters
    private let matchThreshold: Float = 0.60
    private let deadzoneThreshold: Float = 0.48
    private let userMatchThreshold: Float = 0.45
    private let learningThreshold: Float = 0.85
    private let minVolumeThreshold: Float = 0.015
    
    // MARK: - Temporal Continuity & Turn Taking
    private var unknownFrameCount = 0
    private let probationLimit = 5
    private var lastMatchedSpeakerID: Int? = nil
    private var silenceFrameCount = 0
    
    // MARK: - SoundAnalysis Speech Gate
    private let speechGate     = SpeechActivityGate()
    private var soundAnalyzer:  SNAudioStreamAnalyzer?
    private let analysisQueue  = DispatchQueue(label: "com.ansd.soundanalysis", qos: .userInitiated)
    private var analysisFrame:  AVAudioFramePosition = 0

    // MARK: - Published State
    @Published var speakerProfiles: [Int: [Float]] = [:]
    var baseAnchors: [Int: [Float]] = [:]
    private var activeClusters: [Int: [[Float]]] = [:]
    private let maxClusterSize = 15

    @Published var speakerNames:    [Int: String] = [:]
    @Published var currentStatus:   String = "Ready"
    @Published var confidence:      String = "--"
    @Published var isRunning               = false
    @Published var currentSpeakerID: Int?  = nil
    @Published var segmentHistory: [DiarizationEvent] = []

    public var currentLocation: String? = nil
    private var isEnrolling = false
    private var enrollmentCompletion: ((Bool) -> Void)?

    // MARK: - Inference Queue
    private let inferenceQueue = DispatchQueue(label: "com.ansd.audiodiarizer.inference", qos: .userInitiated)
    private var pendingInferenceCount = 0
    private let maxPendingInferences  = 1

    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        do {
            self.model = try VL1004(configuration: config)
            print("✅ VL1004 Model Loaded Successfully")
        } catch {
            print("❌ Model Load Error: \(error)")
        }
        // ⭐️ THE FIX: Pad the initial buffer so it doesn't wait 6 seconds to start!
        resetAudioBuffer()
    }
    
    // ⭐️ THE FIX: Instantly fills the buffer with silence so the first 300ms triggers a prediction.
    private func resetAudioBuffer() {
        collectedSamples = Array(repeating: 0.0, count: requiredSamples - stride)
    }

    // MARK: - Enrollment & Profile Injection
    func enrollUser(completion: @escaping (Bool) -> Void) {
        print("Starting Enrollment for User (ID: 0)...")
        self.isEnrolling = true
        self.enrollmentCompletion = completion
        self.collectedSamples.removeAll()
        self.speakerProfiles.removeAll()
        self.baseAnchors.removeAll()
        self.activeClusters.removeAll()
        self.speakerNames.removeAll()
        self.lastMatchedSpeakerID = nil
        self.unknownFrameCount = 0
    }
    
    func setPreEnrolledProfile(vector: [Float], name: String) {
        self.speakerProfiles[0] = vector
        self.baseAnchors[0] = vector
        self.activeClusters[0] = [vector]
        self.speakerNames[0] = name
        print("✅ Pre-Enrolled Profile Loaded and Anchored for: \(name)")
        resetAudioBuffer() // Ready for instant inference
    }
    
    func setUserName(_ name: String) {
        speakerNames[0] = name
    }

    // MARK: - Audio Processing
    func handleAudio(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        if soundAnalyzer == nil { setupSoundAnalyzer(format: buffer.format) }
        
        let framePos = analysisFrame
        analysisFrame += AVAudioFramePosition(buffer.frameLength)
        let bufferCopy = buffer
        
        analysisQueue.async { [weak self] in
            self?.soundAnalyzer?.analyze(bufferCopy, atAudioFramePosition: framePos)
        }

        guard let converter = getConverter(from: buffer.format, to: targetFormat) else { return }
        let ratio = Float(targetFormat.sampleRate) / Float(buffer.format.sampleRate)
        let capacity = UInt32(Float(buffer.frameLength) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var error: NSError?
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        if let channelData = outputBuffer.floatChannelData {
            var samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(outputBuffer.frameLength)))
            let peakVolume = normalizeAudioSignal(&samples)
            DispatchQueue.main.async { self.processSamples(samples, peakVolume: peakVolume) }
        }
    }

    private func processSamples(_ samples: [Float], peakVolume: Float) {
        let isActivelySpeaking = speechGate.isActive && (peakVolume > minVolumeThreshold)

        if isEnrolling {
            if isActivelySpeaking {
                collectedSamples.append(contentsOf: samples)
                if collectedSamples.count % 16000 == 0 {
                    print("🎙 Enrolling: Captured \(collectedSamples.count)/\(requiredSamples) speech samples...")
                }
            }
        } else {
            if !isActivelySpeaking {
                silenceFrameCount += 1
                if silenceFrameCount == 3 {
                    print("🛑 Turn boundary detected! Wiping acoustic buffer to prevent speaker bleed.")
                    // ⭐️ THE FIX: Don't use zero count, retain the padded size so the NEXT speaker is instant too!
                    resetAudioBuffer()
                    lastMatchedSpeakerID = nil
                }
            } else {
                silenceFrameCount = 0
            }
            
            collectedSamples.append(contentsOf: samples)
        }
        
        guard collectedSamples.count >= requiredSamples else { return }
        let chunk = Array(collectedSamples.prefix(requiredSamples))
        collectedSamples.removeFirst(stride)
        
        if isActivelySpeaking {
            scheduleInference(on: chunk)
        }
    }

    private func scheduleInference(on samples: [Float]) {
        guard pendingInferenceCount <= maxPendingInferences else { return }
        pendingInferenceCount += 1

        inferenceQueue.async { [weak self] in
            defer { DispatchQueue.main.async { self?.pendingInferenceCount -= 1 } }
            self?.runInference(on: samples)
        }
    }

    private func runInference(on samples: [Float]) {
        guard let model = model else { return }
        
        do {
            // ⭐️ FAST INFERENCE: Using the Apple MLShapedArray natively!
            let shapedInput = MLShapedArray<Float>(scalars: samples, shape: [1, requiredSamples])
            let startTime  = CFAbsoluteTimeGetCurrent()
            let prediction = try model.prediction(audio: shapedInput)
            let elapsed    = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            // Extract safely using the auto-generated property
            let vector = prediction.embeddingShapedArray.scalars
            
            DispatchQueue.main.async {
                self.processEmbedding(vector)
            }
        } catch {
            print("❌ Inference Error: \(error)")
        }
    }

    // MARK: - The Match Logic
    private func processEmbedding(_ vector: [Float]) {
        let normVector = normalize(vector)

        if isEnrolling {
            print("✅ User Enrolled (ID 0). Absolute Anchor Set.")
            speakerProfiles[0] = normVector
            baseAnchors[0] = normVector
            activeClusters[0] = [normVector]
            speakerNames[0] = "Me"
            isEnrolling = false
            enrollmentCompletion?(true)
            return
        }

        if speakerProfiles.isEmpty {
            lastMatchedSpeakerID = createNewSpeaker(with: normVector)
            return
        }

        var scoredSpeakers: [(id: Int, score: Float, raw: Float)] = []
        for id in speakerProfiles.keys {
            guard let dynamicProfile = speakerProfiles[id], let anchorProfile = baseAnchors[id] else { continue }
            
            let dynScore = cosineSim(normVector, dynamicProfile)
            let anchorScore = cosineSim(normVector, anchorProfile)
            let raw = max(dynScore, anchorScore)
            var score = raw
            
            if id == 0 { score += 0.04 }
            if id == lastMatchedSpeakerID { score += 0.02 }
            
            score = min(score, 1.0)
            scoredSpeakers.append((id: id, score: score, raw: raw))
        }

        scoredSpeakers.sort { $0.score > $1.score }
        let bestMatch = scoredSpeakers[0]
        
        let threshold = (bestMatch.id == 0) ? userMatchThreshold : matchThreshold

        if bestMatch.score >= threshold {
            matchConfirmed(bestMatch, normVector: normVector)
        } else {
            unknownFrameCount += 1
            if unknownFrameCount >= probationLimit {
                
                if bestMatch.id == 0 && bestMatch.raw >= 0.25 {
                    print("♻️ Identity Recovery: Plausible user signature detected. Force-snapping to ID 0.")
                    matchConfirmed(bestMatch, normVector: normVector)
                }
                else if bestMatch.id != 0 && bestMatch.raw >= 0.35 {
                    print("♻️ Guest Recovery: Plausible guest signature detected. Force-snapping to ID \(bestMatch.id).")
                    matchConfirmed(bestMatch, normVector: normVector)
                }
                else if speechGate.currentConfidence < 0.60 {
                    print("🛡 VAD Confidence (\(String(format: "%.2f", speechGate.currentConfidence))) too low. Rejecting noise frame.")
                    unknownFrameCount -= 1
                }
                else {
                    print("👽 [NEW VOICE] Distinct acoustic signature detected. Creating New Speaker!")
                    lastMatchedSpeakerID = createNewSpeaker(with: normVector)
                    unknownFrameCount = 0
                }
            } else {
                print("🚧 Ambiguous frame (Score \(String(format: "%.2f", bestMatch.score))). Probation: \(unknownFrameCount)/\(probationLimit)")
            }
        }
    }
    
    private func matchConfirmed(_ match: (id: Int, score: Float, raw: Float), normVector: [Float]) {
        unknownFrameCount = 0
        lastMatchedSpeakerID = match.id
        self.confidence = String(format: "%.0f%%", match.score * 100)
        
        print("🎯 Match: Speaker \(match.id) (\(String(format: "%.0f%%", match.score * 100))) [Raw: \(String(format: "%.2f", match.raw))]")
        
        let thresholdForLearning: Float = (match.id == 0) ? userMatchThreshold : matchThreshold
        
        if match.raw > thresholdForLearning && speechGate.isActive {
            print("🧠 Clean speech detected. Updating Centroid for Speaker \(match.id).")
            updateProfile(id: match.id, vector: normVector)
        }
        
        currentSpeakerID = match.id
        addToHistory(vector: normVector, id: match.id, score: match.score)
        
        if segmentHistory.count % 10 == 0 {
            performRetroactiveRefinement()
        }
    }

    // MARK: - 60/40 Profile Centroid Engine
    private func createNewSpeaker(with vector: [Float]) -> Int {
        let newID = (speakerProfiles.keys.max() ?? 0) + 1
        speakerProfiles[newID] = vector
        baseAnchors[newID] = vector
        activeClusters[newID] = [vector]
        currentSpeakerID = newID
        print("👤 New Speaker Identified: ID \(newID)")
        return newID
    }

    private func updateProfile(id: Int, vector: [Float]) {
        guard let anchor = baseAnchors[id] else { return }
        
        if activeClusters[id] == nil { activeClusters[id] = [] }
        activeClusters[id]?.append(vector)
        
        if activeClusters[id]!.count > maxClusterSize {
            activeClusters[id]?.removeFirst()
        }
        
        guard let cluster = activeClusters[id], !cluster.isEmpty else { return }
        
        var clusterSum = [Float](repeating: 0, count: vector.count)
        for v in cluster {
            vDSP_vadd(clusterSum, 1, v, 1, &clusterSum, 1, vDSP_Length(vector.count))
        }
        
        var clusterAvg = [Float](repeating: 0, count: vector.count)
        let countFloat = Float(cluster.count)
        vDSP_vsdiv(clusterSum, 1, [countFloat], &clusterAvg, 1, vDSP_Length(vector.count))
        clusterAvg = normalize(clusterAvg)
        
        var combined = [Float](repeating: 0, count: vector.count)
        var wAnchor: Float = (id == 0) ? 0.85 : 0.60
        var wCluster: Float = (id == 0) ? 0.15 : 0.40
        
        vDSP_vsmul(anchor, 1, &wAnchor, &combined, 1, vDSP_Length(vector.count))
        vDSP_vsma(clusterAvg, 1, &wCluster, combined, 1, &combined, 1, vDSP_Length(vector.count))
        
        let newProfile = normalize(combined)
        
        if id == 0 {
            if cosineSim(newProfile, anchor) < 0.70 {
                return
            }
        }
        
        speakerProfiles[id] = newProfile
    }

    // MARK: - Math & Audio Helpers
    @discardableResult
    private func normalizeAudioSignal(_ samples: inout [Float]) -> Float {
        var maxAmp: Float = 0
        vDSP_maxv(samples, 1, &maxAmp, vDSP_Length(samples.count))
        if maxAmp > 0 {
            var factor = 1.0 / maxAmp
            vDSP_vsmul(samples, 1, &factor, &samples, 1, vDSP_Length(samples.count))
        }
        return maxAmp
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

    private func getConverter(from i: AVAudioFormat, to o: AVAudioFormat) -> AVAudioConverter? {
        if audioConverter == nil || audioConverter?.inputFormat != i { audioConverter = AVAudioConverter(from: i, to: o) }
        return audioConverter
    }

    private func setupSoundAnalyzer(format: AVAudioFormat) {
        let analyzer = SNAudioStreamAnalyzer(format: format)
        do {
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            request.windowDuration = CMTimeMakeWithSeconds(0.5, preferredTimescale: 44100)
            request.overlapFactor = 0.75
            try analyzer.add(request, withObserver: speechGate)
            soundAnalyzer = analyzer
            print("🔊 [SoundAnalysis] Speech gate active (window=0.5s, overlap=75%)")
        } catch {
            print("⚠️ Speech gate error: \(error)")
        }
    }

    // MARK: - Time Machine
    func applyRetroactiveCorrection(forEventID eventID: UUID, newName: String) {
        guard let index = segmentHistory.firstIndex(where: { $0.id == eventID }) else { return }
        let ghostID       = segmentHistory[index].assignedSpeakerID
        let mistakeVector = segmentHistory[index].vector
        let mistakeContext = segmentHistory[index].locationTag

        var targetID: Int = -1

        if let existingID = speakerNames.first(where: { $0.value == newName })?.key {
            targetID = existingID
        } else {
            if ghostID != 0 {
                speakerNames[ghostID] = newName
                self.objectWillChange.send()
                return
            }
            let newID = (speakerProfiles.keys.max() ?? 0) + 1
            speakerProfiles[newID] = mistakeVector
            baseAnchors[newID] = mistakeVector
            activeClusters[newID] = [mistakeVector]
            speakerNames[newID] = newName
            targetID = newID
        }

        updateProfile(id: targetID, vector: mistakeVector)
        guard let targetProfile = speakerProfiles[targetID] else { return }

        for i in 0..<segmentHistory.count {
            let event = segmentHistory[i]

            if event.assignedSpeakerID == ghostID && ghostID != targetID {
                segmentHistory[i].assignedSpeakerID = targetID
                segmentHistory[i].confidence        = 1.0
                updateProfile(id: targetID, vector: event.vector)
                continue
            }

            if event.assignedSpeakerID != 0 && event.assignedSpeakerID != targetID && event.assignedSpeakerID != ghostID {
                var score = cosineSim(event.vector, targetProfile)
                if let evLoc = event.locationTag, let mistLoc = mistakeContext, evLoc == mistLoc { score += 0.10 }

                if score > 0.75 && score > (event.confidence + 0.05) {
                    segmentHistory[i].assignedSpeakerID = targetID
                    segmentHistory[i].confidence        = score
                }
            }
        }

        if ghostID != targetID {
            speakerProfiles.removeValue(forKey: ghostID)
            baseAnchors.removeValue(forKey: ghostID)
            activeClusters.removeValue(forKey: ghostID)
            speakerNames.removeValue(forKey: ghostID)
        }
        self.objectWillChange.send()
    }

    private func addToHistory(vector: [Float], id: Int, score: Float) {
        segmentHistory.append(DiarizationEvent(timestamp: Date(), vector: vector, assignedSpeakerID: id, confidence: score, locationTag: currentLocation))
        if segmentHistory.count > 500 { segmentHistory.removeFirst() }
    }
    
    // MARK: - Proactive Refinement
    func performRetroactiveRefinement() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            var hasChanges = false
            let profiles = self.speakerProfiles
            
            for i in 0..<self.segmentHistory.count {
                let event = self.segmentHistory[i]
                let currentID = event.assignedSpeakerID
                var bestScore: Float = -1.0
                var bestID: Int = currentID
                
                for (id, profile) in profiles {
                    var score = self.cosineSim(event.vector, profile)
                    if id == 0 { score += 0.03 }
                    
                    if score > bestScore {
                        bestScore = score
                        bestID = id
                    }
                }
                
                let threshold = (bestID == 0) ? self.userMatchThreshold : self.matchThreshold
                if bestID != currentID && bestScore > (event.confidence + 0.10) && bestScore >= threshold {
                    DispatchQueue.main.async {
                        self.segmentHistory[i].assignedSpeakerID = bestID
                        self.segmentHistory[i].confidence = bestScore
                    }
                    hasChanges = true
                }
            }
            if hasChanges { DispatchQueue.main.async { self.objectWillChange.send() } }
        }
    }
}

// MARK: - SpeechActivityGate
private class SpeechActivityGate: NSObject, SNResultsObserving {
    private let labels: Set<String> = ["speech"]
    private var _active = true
    private var _currentConfidence: Float = 0.0
    private let lock = NSLock()
    
    var isActive: Bool { lock.lock(); defer { lock.unlock() }; return _active }
    var currentConfidence: Float { lock.lock(); defer { lock.unlock() }; return _currentConfidence }
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let res = result as? SNClassificationResult, let top = res.classifications.first else { return }
        
        lock.lock()
        _currentConfidence = Float(top.confidence)
        // Set to 45% to ensure conversational/quiet speech is actually heard.
        _active = labels.contains(top.identifier) && top.confidence > 0.45
        lock.unlock()
    }
}
