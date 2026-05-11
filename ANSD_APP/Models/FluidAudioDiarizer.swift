//
//  FluidAudioDiarizer.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 11/05/26.
//  Strictly FluidAudio implementation.
//

import Foundation
import AVFoundation
import Combine
import FluidAudio

struct DiarizationEvent {
    let id: UUID
    let timestamp: Date
    var assignedSpeakerID: Int
}

class FluidAudioDiarizer: ObservableObject {

    // MARK: - FluidAudio Components
    private var diarizer: SortformerDiarizer?
    private var vadManager: VadManager?
    
    // MARK: - State Properties
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
    
    private let inferenceQueue = DispatchQueue(label: "com.ansd.diarizer.fluid", qos: .userInitiated)

    init() {
        setupFluidAudio()
    }

    private func setupFluidAudio() {
        Task {
            do {
                let vadConfig = VadConfig(threshold: 0.5, chunkSize: 512, sampleRate: 16000)
                self.vadManager = VadManager(config: vadConfig)
                try await self.vadManager?.initialize()
                
                self.diarizer = SortformerDiarizer()
                
                print("[FluidAudioDiarizer] Native SDK initialized.")
                await MainActor.run {
                    self.currentStatus = "Ready"
                }
            } catch {
                print("[FluidAudioDiarizer] Init Error: \(error)")
                await MainActor.run {
                    self.currentStatus = "Init Error"
                }
            }
        }
    }

    func getSpeaker(at date: Date) -> Int? {
        guard !segmentHistory.isEmpty else { return nil }
        if let event = segmentHistory.last(where: { $0.timestamp <= date }) {
            return event.assignedSpeakerID
        }
        return segmentHistory.last?.assignedSpeakerID
    }

    func setPreEnrolledProfile(vector: [Float], name: String) {
        speakerNames[0] = name
        // FluidAudio handles enrollment internally
    }

    func startIntroCalibration(completion: @escaping (Int) -> Void) {
        isIntroCalibrating = true
        introCompletion = completion
    }

    func applyRetroactiveCorrection(forEventID eventID: UUID, newName: String) {
        guard let eventIdx = segmentHistory.firstIndex(where: { $0.id == eventID }) else { return }
        let speakerID = segmentHistory[eventIdx].assignedSpeakerID
        speakerNames[speakerID] = newName
        segmentHistory = segmentHistory // Trigger UI
    }

    func handleAudio(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        guard let vad = vadManager, let diarizer = diarizer else { return }
        
        let samples = convertBufferToSamples(buffer, targetFormat: targetFormat)
        guard !samples.isEmpty else { return }

        inferenceQueue.async {
            Task {
                do {
                    let vadResult = try await vad.processChunk(samples)
                    if vadResult.isVoiceActive {
                        diarizer.addAudio(samples, sourceSampleRate: 16000)
                        if let update = diarizer.process() {
                            await MainActor.run {
                                self.processDiarizationUpdate(update)
                            }
                        }
                    } else {
                        await MainActor.run { self.currentSpeakerID = nil }
                    }
                } catch {
                    print("[FluidAudioDiarizer] Error: \(error)")
                }
            }
        }
    }

    private func convertBufferToSamples(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) -> [Float] {
        let converter = AVAudioConverter(from: buffer.format, to: targetFormat)
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let targetFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: targetFrameCount) else { return [] }
        
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, status in
            status.pointee = .haveData
            return buffer
        }
        converter?.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if let data = outputBuffer.floatChannelData {
            return Array(UnsafeBufferPointer(start: data[0], count: Int(outputBuffer.frameLength)))
        }
        return []
    }

    private func processDiarizationUpdate(_ update: DiarizationUpdate) {
        let speakerID = update.speakerId
        if isIntroCalibrating {
            isIntroCalibrating = false
            speakerNames[speakerID] = "Speaker \(speakerID)"
            introCompletion?(speakerID)
            introCompletion = nil
        }
        
        self.currentSpeakerID = speakerID
        self.confidence = String(format: "%.2f", update.probability)
        segmentHistory.append(DiarizationEvent(id: UUID(), timestamp: Date(), assignedSpeakerID: speakerID))
        currentStatus = "Speaker \(speakerID) Active"
    }

    func stop() {
        isRunning = false
        diarizer = nil
        vadManager = nil
        setupFluidAudio()
    }
}

// SDK Interface Shims
struct DiarizationUpdate {
    let speakerId: Int
    let probability: Float
}
