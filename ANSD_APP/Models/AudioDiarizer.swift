//
//  AudioDiarizer.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import AVFoundation
import CoreML
import Accelerate
import Combine

struct DiarizationEvent {
    let id: UUID
    let timestamp: Date
    var assignedSpeakerID: Int
}

class AudioDiarizer: ObservableObject {

    private var model: VL1004?
    private var audioConverter: AVAudioConverter?
    private let requiredSamples = 96000
    private var collectedSamples: [Float] = []

    private let learningRate: Float = 0.15 // Faster learning to keep up with music/shouting
    private let similarityThreshold: Float = 0.42
    private let learningThreshold: Float = 0.48
    private let speakerBias: Float = 0.15 // 15% bonus for the current speaker to stay "sticky"

    private let vad = SileroVADProcessor()
    private var vadInputBuffer: [Float] = []
    
    // Memory & Smoothing
    private var consecutiveMismatches = 0
    private let mismatchThreshold = 3 // Must fail 3 times before creating a new ID
    private var pendingNewSpeakerVector: [Float]? = nil
    private var prerollBuffer: [Float] = []
    private let prerollMaxSamples = SileroVADProcessor.chunkSize * 2
    private var silentFrameCount = 0
    private let silenceResetFrames = 40

    @Published var speakerProfiles: [Int: [Float]] = [:]
    @Published var currentStatus: String = "Ready"
    @Published var confidence: String = "--"
    @Published var isRunning: Bool = false
    @Published var currentSpeakerID: Int? = nil
    @Published var segmentHistory: [DiarizationEvent] = []

    var speakerNames: [Int: String] = [:]
    var currentLocation: String = "Unknown"

    private var isIntroCalibrating: Bool = false
    private var introCompletion: ((Int) -> Void)?
    
    // Serial queue for ML inference to prevent blocking the audio thread (HALC overload)
    private let inferenceQueue = DispatchQueue(label: "com.ansd.diarizer.inference", qos: .userInitiated)

    init() {
        let config = MLModelConfiguration()
        #if targetEnvironment(simulator)
        config.computeUnits = .cpuOnly // Prevents Espresso/MPSGraph errors in Simulator
        #else
        config.computeUnits = .all
        #endif
        do {
            model = try VL1004(configuration: config)
        } catch {
            print("[AudioDiarizer] Model Load Error: \(error)")
        }
    }

    func setPreEnrolledProfile(vector: [Float], name: String) {
        speakerProfiles[0] = vector
        speakerNames[0] = name
    }

    func enrollUser(completion: @escaping (Bool) -> Void) {
        // ENDGAME OPTIMIZATION: Don't stop/clear buffer, just set the flag
        isEnrolling = true
        enrollmentCompletion = completion
        print("[AudioDiarizer] Starting User Enrollment (Endgame Logic)...")
    }

    private var isEnrolling: Bool = false
    private var enrollmentCompletion: ((Bool) -> Void)?

    func startIntroCalibration(completion: @escaping (Int) -> Void) {
        // We don't stop the diarizer, we just set a flag to intercept the next inference
        isIntroCalibrating = true
        introCompletion = completion
        // Clear buffer so we get a fresh 6s of the new speaker
        collectedSamples.removeAll()
        print("[AudioDiarizer] Starting Seamless Intro Calibration...")
    }

    func setUserName(_ name: String) {
        speakerNames[0] = name
    }

    /// Fixed: Added Centroid Merging to handle "I became 2" cases.
    func applyRetroactiveCorrection(forEventID eventID: UUID, newName: String) {
        guard let eventIdx = segmentHistory.firstIndex(where: { $0.id == eventID }) else { return }
        let oldID = segmentHistory[eventIdx].assignedSpeakerID
        
        // 1. Check if name already exists (Merge case)
        if let existingID = speakerNames.first(where: { $0.value == newName })?.key, existingID != oldID {
            print("[AudioDiarizer] Merging Speaker \(oldID) into Speaker \(existingID) (\(newName))")
            
            // Mathematically merge centroids to prevent future drift
            if let oldProfile = speakerProfiles[oldID], let existingProfile = speakerProfiles[existingID] {
                speakerProfiles[existingID] = applyRollingAvg(old: existingProfile, new: oldProfile)
            }
            
            // Retroactively update history for this session
            for i in 0..<segmentHistory.count {
                if segmentHistory[i].assignedSpeakerID == oldID {
                    segmentHistory[i].assignedSpeakerID = existingID
                }
            }
            
            // Cleanup the ghost ID
            speakerProfiles.removeValue(forKey: oldID)
            speakerNames.removeValue(forKey: oldID)
            
            // Trigger UI Refresh
            let historyCopy = segmentHistory
            segmentHistory = historyCopy
            currentSpeakerID = existingID
            
        } else {
            // 2. Simple Rename case
            speakerNames[oldID] = newName
            let historyCopy = segmentHistory
            segmentHistory = historyCopy
        }
    }

    func handleAudio(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        if audioConverter == nil || audioConverter?.inputFormat != buffer.format {
            audioConverter = AVAudioConverter(from: buffer.format, to: targetFormat)
        }
        guard let converter = audioConverter else { return }
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let targetCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: targetCapacity) else { return }
        var gotData = false
        let inputBlock: AVAudioConverterInputBlock = { _, status in
            if gotData { status.pointee = .noDataNow; return nil }
            gotData = true; status.pointee = .haveData; return buffer
        }
        try? converter.convert(to: out, error: nil, withInputFrom: inputBlock)
        guard let data = out.floatChannelData else { return }
        let samples = Array(UnsafeBufferPointer(start: data[0], count: Int(out.frameLength)))
        accumulateWithVAD(samples: samples)
        while collectedSamples.count >= requiredSamples {
            let chunk = Array(collectedSamples.prefix(requiredSamples))
            collectedSamples.removeFirst(16000)
            runInference(samples: chunk)
        }
    }

    private func accumulateWithVAD(samples: [Float]) {
        let chunkSize = SileroVADProcessor.chunkSize
        vadInputBuffer.append(contentsOf: samples)
        while vadInputBuffer.count >= chunkSize {
            let chunk = Array(vadInputBuffer.prefix(chunkSize))
            vadInputBuffer.removeFirst(chunkSize)
            if vad.isSpeech(samples: chunk) {
                collectedSamples.append(contentsOf: prerollBuffer)
                prerollBuffer.removeAll()
                collectedSamples.append(contentsOf: chunk)
                silentFrameCount = 0
            } else {
                prerollBuffer.append(contentsOf: chunk)
                if prerollBuffer.count > prerollMaxSamples { prerollBuffer.removeFirst(chunkSize) }
                silentFrameCount += 1
                // ENDGAME OPTIMIZATION: We no longer wipe the buffer during silence.
                // This keeps the 6s context alive for better stability.
            }
        }
    }

    private func runInference(samples: [Float]) {
        guard let model = model else { return }
        
        // Offload to background queue to prevent HALC ProxyIOContext overload
        inferenceQueue.async {
            do {
                let input = try MLMultiArray(shape: [1, NSNumber(value: self.requiredSamples)], dataType: .float32)
                for (i, s) in samples.enumerated() { input[i] = NSNumber(value: s) }
                let output = try model.prediction(audio: input)
                let vector = self.normalize(self.convertToFloat(output.embedding))
                DispatchQueue.main.async { self.processResult(vector) }
            } catch {
                print("[AudioDiarizer] Inference failed: \(error)")
            }
        }
    }

    private func processResult(_ vector: [Float]) {
        if isEnrolling {
            speakerProfiles[0] = vector
            isEnrolling = false
            enrollmentCompletion?(true)
            enrollmentCompletion = nil
            return
        }

        if isIntroCalibrating {
            let newID = speakerProfiles.count
            speakerProfiles[newID] = vector
            speakerNames[newID] = "Speaker \(newID)"
            isIntroCalibrating = false
            introCompletion?(newID)
            introCompletion = nil
            currentSpeakerID = newID
            segmentHistory.append(DiarizationEvent(id: UUID(), timestamp: Date(), assignedSpeakerID: newID))
            return
        }

        var bestID = -1
        var maxScore: Float = -1.0

        for (id, profile) in speakerProfiles {
            var score = cosineSim(vector, profile)
            
            // MEMORY: Apply bias to the current speaker to prevent "jitter"
            if id == currentSpeakerID {
                score *= (1.0 + speakerBias)
            }
            
            if score > maxScore {
                maxScore = score
                bestID = id
            }
        }

        if maxScore > similarityThreshold {
            // Match found - Reset mismatches
            consecutiveMismatches = 0
            pendingNewSpeakerVector = nil
            
            updateSpeaker(id: bestID, vector: vector, score: maxScore)
            currentSpeakerID = bestID
            segmentHistory.append(DiarizationEvent(id: UUID(), timestamp: Date(), assignedSpeakerID: bestID))
        } else {
            // PROBATION: Don't create a new speaker immediately. 
            // We need 3 consecutive windows of "new" voice to be sure.
            consecutiveMismatches += 1
            
            if consecutiveMismatches < mismatchThreshold {
                // Stay on current speaker for now (smoothing)
                if let cid = currentSpeakerID {
                    segmentHistory.append(DiarizationEvent(id: UUID(), timestamp: Date(), assignedSpeakerID: cid))
                }
                print("[AudioDiarizer] Smoothing mismatch (\(consecutiveMismatches)/\(mismatchThreshold))...")
            } else {
                // OK, it's really a new person.
                consecutiveMismatches = 0
                let newID = speakerProfiles.count
                speakerProfiles[newID] = vector
                speakerNames[newID] = "Speaker \(newID)"
                currentSpeakerID = newID
                segmentHistory.append(DiarizationEvent(id: UUID(), timestamp: Date(), assignedSpeakerID: newID))
                print("[AudioDiarizer] New Speaker confirmed: \(newID). Confidence: \(maxScore)")
                
                // SELF-FIX: Try to merge this new speaker with any existing one 
                // if they are actually similar (Automatic Consolidation)
                mergeSimilarSpeakers()
            }
        }
    }

    private func mergeSimilarSpeakers() {
        let keys = speakerProfiles.keys.sorted()
        guard keys.count > 1 else { return }
        
        for i in 0..<keys.count {
            for j in (i + 1)..<keys.count {
                let id1 = keys[i]
                let id2 = keys[j]
                guard let p1 = speakerProfiles[id1], let p2 = speakerProfiles[id2] else { continue }
                
                let similarity = cosineSim(p1, p2)
                if similarity > (similarityThreshold * 0.95) { // If they are very close
                    print("[AudioDiarizer] SELF-FIX: Merging Speaker \(id2) into Speaker \(id1) (Similarity: \(similarity))")
                    
                    // Combine profiles
                    speakerProfiles[id1] = applyRollingAvg(old: p1, new: p2)
                    speakerProfiles.removeValue(forKey: id2)
                    speakerNames.removeValue(forKey: id2)
                    
                    // Update current speaker if necessary
                    if currentSpeakerID == id2 { currentSpeakerID = id1 }
                    
                    // Retroactively fix history
                    for k in 0..<segmentHistory.count {
                        if segmentHistory[k].assignedSpeakerID == id2 {
                            segmentHistory[k].assignedSpeakerID = id1
                        }
                    }
                    
                    // Recursive call to catch other merges
                    mergeSimilarSpeakers()
                    return
                }
            }
        }
    }

    private func updateSpeaker(id: Int, vector: [Float], score: Float) {
        confidence = String(format: "%.2f", score)
        if score > learningThreshold, let old = speakerProfiles[id] {
            speakerProfiles[id] = applyRollingAvg(old: old, new: vector)
        }
    }

    func stop() {
        isRunning = false; isEnrolling = false; collectedSamples.removeAll()
        vadInputBuffer.removeAll(); prerollBuffer.removeAll(); silentFrameCount = 0
    }

    private func applyRollingAvg(old: [Float], new: [Float]) -> [Float] {
        var result = [Float](repeating: 0, count: old.count)
        var fOld = 1.0 - learningRate; var fNew = learningRate
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

    func convertToFloat(_ mlArray: MLMultiArray) -> [Float] {
        let ptr = mlArray.dataPointer.bindMemory(to: Float.self, capacity: mlArray.count)
        return Array(UnsafeBufferPointer(start: ptr, count: mlArray.count))
    }
}
