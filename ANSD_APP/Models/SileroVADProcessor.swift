//
//  SileroVADProcessor.swift
//  ANSD_APP
//
//  Created by Antigravity on 06/05/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//
//  Voice Activity Detection for the AudioDiarizer accumulator gate.
//
//  Primary path  - SileroVAD.mlpackage (when available in bundle)
//  Fallback path - Adaptive energy-based VAD (Accelerate, zero dependencies)
//

import Foundation
import CoreML
import Accelerate

final class SileroVADProcessor {

    // MARK: - Constants

    /// Silero VAD expects exactly 512 samples per inference call (32 ms @ 16 kHz).
    static let chunkSize = 512

    // MARK: - Hysteresis Parameters
    
    /// Consecutive speech frames needed to flip to speech state.
    private let speechTriggerFrames  = 2
    /// Consecutive silence frames needed to flip to silence state.
    private let silenceTriggerFrames = 15

    // MARK: - Energy VAD Parameters
    
    /// SNR ratio above which a frame is considered speech.
    private let speechSNRThreshold: Float  = 3.5
    /// SNR ratio below which a frame is considered silence.
    private let silenceSNRThreshold: Float = 2.0
    /// Adaptation rate of the noise floor estimate.
    private var noiseFloor: Float          = 1e-4

    // MARK: - State

    private var model: SileroVAD?
    private var consecutiveSpeechFrames  = 0
    private var consecutiveSilenceFrames = 0
    private var currentVADState          = false

    // MARK: - Public API

    /// Whether the processor is ready to handle audio.
    var isAvailable: Bool { true }

    /// Whether the neural Silero model is being used.
    var usingSileroModel: Bool { model != nil }

    // MARK: - Init

    init() {
        let config = MLModelConfiguration()
        #if targetEnvironment(simulator)
        config.computeUnits = .cpuOnly // Prevents Espresso/MPSGraph errors in Simulator
        #else
        config.computeUnits = .cpuAndNeuralEngine
        #endif

        do {
            self.model = try SileroVAD(configuration: config)
            print("[VAD] Silero neural model initialized.")
        } catch {
            print("[VAD] Info: Silero model not found. Using adaptive energy-based VAD. Error: \(error)")
        }
    }

    /// Feed exactly `SileroVADProcessor.chunkSize` samples @ 16 kHz.
    /// Returns true when voice activity is detected.
    func isSpeech(samples: [Float]) -> Bool {
        guard samples.count == Self.chunkSize else { return true }

        let rawProb = model != nil
            ? sileroProb(samples: samples)
            : energyProb(samples: samples)

        return applyHysteresis(prob: rawProb)
    }

    /// Resets temporal state between sessions.
    func reset() {
        consecutiveSpeechFrames  = 0
        consecutiveSilenceFrames = 0
        currentVADState          = false
        noiseFloor               = 1e-4
    }

    // MARK: - Inference Paths

    private func sileroProb(samples: [Float]) -> Float {
        guard let model = model else { return energyProb(samples: samples) }
        do {
            let audioArr = try MLMultiArray(shape: [1, 512], dataType: .float32)
            for (i, s) in samples.enumerated() { audioArr[i] = NSNumber(value: s) }

            // Use the generic prediction API to be safe against property naming variations
            let inputName = "audio_chunk" 
            let input = try MLDictionaryFeatureProvider(dictionary: [inputName: MLFeatureValue(multiArray: audioArr)])
            let output = try model.model.prediction(from: input)

            if let prob = output.featureValue(for: "speech_prob")?.multiArrayValue?[0].floatValue {
                return prob
            }
            
            // Backup: search for any multi-array output if "speech_prob" isn't the key
            for name in output.featureNames {
                if let prob = output.featureValue(for: name)?.multiArrayValue?[0].floatValue {
                    return prob
                }
            }
            return 0.0
        } catch {
            return energyProb(samples: samples)
        }
    }

    private func energyProb(samples: [Float]) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))

        let noiseAdaptRate: Float = rms < noiseFloor * 2.0 ? 0.02 : 0.001
        noiseFloor = noiseFloor * (1 - noiseAdaptRate) + rms * noiseAdaptRate

        let snr = rms / (noiseFloor + 1e-8)
        let span = speechSNRThreshold - silenceSNRThreshold
        return min(1.0, max(0.0, (snr - silenceSNRThreshold) / span))
    }

    private func applyHysteresis(prob: Float) -> Bool {
        let speechThr:  Float = 0.5
        let silenceThr: Float = 0.35

        if prob >= speechThr {
            consecutiveSpeechFrames  += 1
            consecutiveSilenceFrames  = 0
            if consecutiveSpeechFrames >= speechTriggerFrames {
                currentVADState = true
            }
        } else if prob < silenceThr {
            consecutiveSilenceFrames += 1
            consecutiveSpeechFrames   = 0
            if consecutiveSilenceFrames >= silenceTriggerFrames {
                currentVADState = false
            }
        }
        return currentVADState
    }
}
