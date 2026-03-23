//
//  DiarizationUtils.swift
//  ANSD_APP
//
//  Created by Antigravity on 23/03/26.
//

import Foundation
import Accelerate

struct DiarizationUtils {
    
    // MARK: - Audio Normalization
    
    /// Normalizes the input audio samples to a target RMS level (e.g., -20dB).
    /// This ensures consistent embedding quality regardless of microphone distance or volume.
    static func normalizeAudio(_ samples: [Float]) -> [Float] {
        guard !samples.isEmpty else { return samples }
        
        // 1. Calculate current RMS
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
        
        // 2. Define target RMS (approx -20dB FS)
        let targetRMS: Float = 0.1
        
        // 3. Prevent division by zero or extreme amplification of floor noise
        let currentRMS = max(rms, 0.001)
        let multiplier = targetRMS / currentRMS
        
        // 4. Scale samples to target RMS
        var normalized = [Float](repeating: 0, count: samples.count)
        var scale = multiplier
        vDSP_vsmul(samples, 1, &scale, &normalized, 1, vDSP_Length(samples.count))
        
        // 5. Peak Clipping Guard: ensure no samples exceed [-1.0, 1.0]
        var maxVal: Float = 1.0
        var minVal: Float = -1.0
        vDSP_vclip(normalized, 1, &minVal, &maxVal, &normalized, 1, vDSP_Length(normalized.count))
        
        return normalized
    }
    
    // MARK: - Signal Processing
    
    /// Applies a first-order high-pass filter to emphasize speech formants.
    /// Formula: y[n] = x[n] - 0.97 * x[n-1]
    static func preEmphasize(_ samples: [Float]) -> [Float] {
        guard samples.count > 1 else { return samples }
        var result = [Float](repeating: 0, count: samples.count)
        result[0] = samples[0]
        
        let alpha: Float = 0.97
        for i in 1..<samples.count {
            result[i] = samples[i] - alpha * samples[i-1]
        }
        return result
    }
    
    // MARK: - Vector Math
    
    /// Normalizes a vector to unit length (L2 normalization).
    static func l2Normalize(_ v: [Float]) -> [Float] {
        var norm: Float = 0
        vDSP_svesq(v, 1, &norm, vDSP_Length(v.count))
        let mag = sqrt(norm) + 1e-9
        var res = [Float](repeating: 0, count: v.count)
        vDSP_vsdiv(v, 1, [mag], &res, 1, vDSP_Length(v.count))
        return res
    }
    
    /// Calculates the cosine similarity between two vectors.
    static func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        guard v1.count == v2.count else { return 0 }
        var dot: Float = 0
        vDSP_dotpr(v1, 1, v2, 1, &dot, vDSP_Length(v1.count))
        return dot
    }

    /// Calculates the centroid of a collection of vectors and normalizes it.
    static func calculateCentroid(_ vectors: [[Float]]) -> [Float] {
        guard !vectors.isEmpty else { return [] }
        var centroid = [Float](repeating: 0, count: vectors[0].count)
        for v in vectors {
            vDSP_vadd(centroid, 1, v, 1, &centroid, 1, vDSP_Length(centroid.count))
        }
        return l2Normalize(centroid)
    }
}
