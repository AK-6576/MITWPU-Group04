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
    private let learningThreshold: Float = 0.85 // Strict: only learn from high-quality audio
    private let learningRate: Float = 0.05
    
    // MARK: - Temporal Continuity & Probation
    private var unknownFrameCount = 0
    private let probationLimit = 4 // Increased to 1.2s to completely ride out transitions
    private var lastMatchedSpeakerID: Int? = nil
    
    // MARK: - SoundAnalysis Speech Gate
    private let speechGate     = SpeechActivityGate()
    private var soundAnalyzer:  SNAudioStreamAnalyzer?
    private let analysisQueue  = DispatchQueue(label: "com.ansd.soundanalysis", qos: .userInitiated)
    private var analysisFrame:  AVAudioFramePosition = 0

    // MARK: - Published State
    @Published var speakerProfiles: [Int: [Float]] = [:]
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
    }

    // MARK: - Enrollment
    func enrollUser(completion: @escaping (Bool) -> Void) {
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
            normalizeAudioSignal(&samples)
            DispatchQueue.main.async { self.processSamples(samples) }
        }
    }

    private func processSamples(_ samples: [Float]) {
        if speechGate.isActive {
            collectedSamples.append(contentsOf: samples)
        }
        
        guard collectedSamples.count >= requiredSamples else { return }
        let chunk = Array(collectedSamples.prefix(requiredSamples))
        collectedSamples.removeFirst(stride)
        scheduleInference(on: chunk)
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
        guard let model = model,
              let input = try? MLMultiArray(shape: [1, NSNumber(value: requiredSamples)], dataType: .float32) else { return }
        
        for (i, s) in samples.enumerated() { input[i] = NSNumber(value: s) }
        
        do {
            let prediction = try model.prediction(audio: input)
            let vector = extractVector(from: prediction.embedding)
            DispatchQueue.main.async { self.processEmbedding(vector) }
        } catch {
            print("❌ Inference Error: \(error)")
        }
    }

    // MARK: - The "Identity-Lock" Match Logic
    private func processEmbedding(_ vector: [Float]) {
        let normVector = normalize(vector)

        if isEnrolling {
            print("✅ User Enrolled (ID 0). Anchor Set.")
            speakerProfiles[0] = normVector
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
        for (id, profile) in speakerProfiles {
            let raw = cosineSim(normVector, profile)
            var score = raw
            
            // ⭐️ THE SUPER-MAGNET: ID 0 gets a massive advantage to reclaim identity
            if id == 0 { score += 0.08 }
            
            // Continuity boost
            if id == lastMatchedSpeakerID { score += 0.04 }
            
            score = min(score, 1.0)
            scoredSpeakers.append((id: id, score: score, raw: raw))
        }

        scoredSpeakers.sort { $0.score > $1.score }
        let bestMatch = scoredSpeakers[0]

        if bestMatch.score >= matchThreshold {
            // CONFIRMED MATCH
            unknownFrameCount = 0
            lastMatchedSpeakerID = bestMatch.id
            self.confidence = String(format: "%.0f%%", bestMatch.score * 100)
            
            // ⭐️ ID 0 IS ALLOWED TO LEARN: If the raw score is very high (>0.85), allow ID 0 to adapt to the room!
            if bestMatch.raw > learningThreshold {
                updateProfile(id: bestMatch.id, vector: normVector)
            }
            
            currentSpeakerID = bestMatch.id
            addToHistory(vector: normVector, id: bestMatch.id, score: bestMatch.score)
            
        } else if bestMatch.score < deadzoneThreshold {
            // POTENTIAL NEW SPEAKER (Probation Phase)
            unknownFrameCount += 1
            if unknownFrameCount >= probationLimit {
                lastMatchedSpeakerID = createNewSpeaker(with: normVector)
                unknownFrameCount = 0
            }
        }
    }

    // MARK: - Profile Management
    private func createNewSpeaker(with vector: [Float]) -> Int {
        let newID = (speakerProfiles.keys.max() ?? 0) + 1
        speakerProfiles[newID] = vector
        currentSpeakerID = newID
        print("👤 New Speaker Identified: ID \(newID)")
        return newID
    }

    private func updateProfile(id: Int, vector: [Float]) {
        if let old = speakerProfiles[id] {
            speakerProfiles[id] = applyRollingAvg(old: old, new: vector)
        }
    }

    // MARK: - Math & Audio Helpers
    private func normalizeAudioSignal(_ samples: inout [Float]) {
        var maxAmp: Float = 0
        vDSP_maxv(samples, 1, &maxAmp, vDSP_Length(samples.count))
        if maxAmp > 0 {
            var factor = 1.0 / maxAmp
            vDSP_vsmul(samples, 1, &factor, &samples, 1, vDSP_Length(samples.count))
        }
    }

    private func applyRollingAvg(old: [Float], new: [Float]) -> [Float] {
        var result = [Float](repeating: 0, count: old.count)
        var fOld = 1.0 - learningRate, fNew = learningRate
        vDSP_vsmul(old, 1, &fOld, &result, 1, vDSP_Length(old.count))
        vDSP_vsma(new, 1, &fNew, result, 1, &result, 1, vDSP_Length(old.count))
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
        let ptr = multiArray.dataPointer.bindMemory(to: Float.self, capacity: count)
        return Array(UnsafeBufferPointer(start: ptr, count: count))
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
        } catch { print("Speech gate error: \(error)") }
    }

    // MARK: - Time Machine
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

            if event.assignedSpeakerID == ghostID && ghostID != targetID {
                segmentHistory[i].assignedSpeakerID = targetID
                segmentHistory[i].confidence        = 1.0
                updateProfile(id: targetID, vector: event.vector)
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
    }

    private func addToHistory(vector: [Float], id: Int, score: Float) {
        segmentHistory.append(DiarizationEvent(timestamp: Date(), vector: vector, assignedSpeakerID: id, confidence: score, locationTag: currentLocation))
        if segmentHistory.count > 500 { segmentHistory.removeFirst() }
    }
}

// MARK: - SpeechActivityGate
private class SpeechActivityGate: NSObject, SNResultsObserving {
    private let labels: Set<String> = ["speech", "singing", "shout", "laughter"]
    private var _active = true
    private let lock = NSLock()
    var isActive: Bool { lock.lock(); defer { lock.unlock() }; return _active }
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let res = result as? SNClassificationResult, let top = res.classifications.first else { return }
        lock.lock(); _active = labels.contains(top.identifier) && top.confidence > 0.15; lock.unlock()
    }
}
