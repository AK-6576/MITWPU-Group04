//
//  SemanticDiarizationAdvisor.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 26/03/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import FoundationModels

@available(iOS 18.1, *)
final class SemanticDiarizationAdvisor {
    
    // MARK: - Structured Output
    
    /// The LLM returns a boolean prediction plus a confidence score so the
    /// caller can filter out low-quality guesses.
    @Generable
    struct Prediction {
        @Guide(description: """
        Set to true ONLY if the next utterance in the conversation is very \
        likely to come from a DIFFERENT speaker than the last one, based on \
        conversational cues such as: a direct question expecting an answer, \
        a topic hand-off, a reply word ('Yes', 'No', 'Sure', 'Right'), or a \
        clear change in speaking style. Default to false when uncertain.
        """)
        var expectsSpeakerChange: Bool
        
        @Guide(description: """
        Your confidence in the prediction, from 0.0 (pure guess) to 1.0 \
        (extremely certain). Output 0.5 or lower when unsure. Only output \
        above 0.7 when conversational cues are unambiguous (e.g. a direct \
        question mark or an explicit hand-off phrase).
        """)
        var confidence: Double
    }
    
    // MARK: - System Instructions (sent once per session, not per call)
    
    /// Static role description + rules + few-shot examples.
    /// Using `LanguageModelSession(instructions:)` gives these system-level
    /// priority in the model and avoids re-sending ~150 tokens every call.
    private let systemInstructions = """
    You are a real-time conversation-turn detector embedded in a captioning \
    app for people with hearing loss. Your ONLY job is to predict whether the \
    NEXT utterance will come from a DIFFERENT speaker than the last one shown.

    RULES:
    1. Predict change=true for unanswered questions, reply starters, or \
       clear topic hand-offs.
    2. Predict change=false when the last speaker is continuing a thought, \
       listing items, or narrating.
    3. When in doubt, predict false - the acoustic model is the primary \
       signal; you are a supplementary hint.
    4. Set confidence >= 0.7 ONLY when the cue is unambiguous.

    EXAMPLES:

    Example 1 - Direct question (change=true, high confidence):
    [Alice]: So what did the doctor say about the results?
    expectsSpeakerChange=true, confidence=0.85
    Reason: Direct question addressed to someone else; an answer is expected.

    Example 2 - Same speaker continuing (change=false):
    [Bob]: I went to the store yesterday. I picked up some milk, bread, \
    and eggs. Oh and I also got that cereal you like.
    expectsSpeakerChange=false, confidence=0.80
    Reason: Speaker is listing items and continuing their narrative.

    Example 3 - Greeting reply (change=true):
    [Alice]: Hey! How have you been?
    expectsSpeakerChange=true, confidence=0.90
    Reason: Greeting with a question; social convention demands a reply.

    Example 4 - Trailing statement, no cue (change=false, low confidence):
    [Bob]: Yeah that makes sense.
    expectsSpeakerChange=false, confidence=0.45
    Reason: Acknowledgement - could go either way; default to false.
    """
    
    // MARK: - Configuration
    
    /// Minimum LLM confidence required to report a speaker change.
    /// Below this threshold the prediction is treated as `false`.
    private let confidenceThreshold: Double = 0.6
    
    /// Rolling context window: last N utterances sent to the LLM.
    /// 10 utterances is roughly 60-90 s of conversation, enough for multi-turn
    /// pattern detection while staying well within the 4K token limit.
    private let maxContext = 10
    
    /// The LLM session is rotated after this many predictions to prevent
    /// the internal transcript from exceeding the 4,096-token context window.
    private let maxPredictionsPerSession = 20
    
    /// Minimum seconds between consecutive LLM calls.
    /// Prevents prediction pile-up during rapid-fire bubble finalizations.
    private let cooldownInterval: TimeInterval = 2.0
    
    // MARK: - State
    
    private var session: LanguageModelSession
    private var context: [(speaker: String, text: String)] = []
    private var predictionCount = 0
    private var lastPredictionTime: Date = .distantPast
    private var lastResult: Bool = false   // cached result for cooldown hits
    
    // MARK: - Init
    
    init() {
        session = LanguageModelSession(instructions: systemInstructions)
        
        // Prewarm the model so the first real prediction doesn't pay
        // full cold-start latency (~1-2s on A17+).
        Task {
            do {
                try await session.prewarm()
                print("[SemanticAdvisor] Model prewarmed - ready for low-latency predictions")
            } catch {
                // Non-fatal; the first prediction will just be slightly slower.
                print("[SemanticAdvisor] Prewarm skipped: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Public API
    
    /// Append a finalised utterance to the rolling context window.
    func record(speaker: String, text: String) {
        context.append((speaker: speaker, text: text))
        if context.count > maxContext { context.removeFirst() }
    }
    
    /// Predict whether the next utterance will come from a different speaker.
    /// Returns `false` immediately when Apple Intelligence is unavailable,
    /// context is too thin (< 2 utterances), or the cooldown hasn't elapsed.
    func predictSpeakerChange() async -> Bool {
        guard SystemLanguageModel.default.isAvailable,
              context.count >= 2 else { return false }
        
        // Cooldown: return cached result if called too soon
        let now = Date()
        if now.timeIntervalSince(lastPredictionTime) < cooldownInterval {
            print("[SemanticAdvisor] Cooldown active - returning cached result: \(lastResult)")
            return lastResult
        }
        lastPredictionTime = now
        
        // Session rotation: prevent 4K token overflow
        if predictionCount >= maxPredictionsPerSession {
            session = LanguageModelSession(instructions: systemInstructions)
            predictionCount = 0
            print("[SemanticAdvisor] Session rotated (token budget refresh)")
        }
        
        // Build the per-call prompt (dialogue only - role/rules are in instructions)
        let dialogue = context
            .map { "[\($0.speaker)]: \($0.text)" }
            .joined(separator: "\n")
        
        let prompt = """
        Analyse this conversation and predict whether the NEXT utterance \
        will come from a DIFFERENT speaker than the last one shown.
        
        Conversation so far:
        \(dialogue)
        """
        
        do {
            let response = try await session.respond(to: prompt,
                                                      generating: Prediction.self)
            predictionCount += 1
            
            let prediction = response.content
            let accepted = prediction.expectsSpeakerChange
                        && prediction.confidence >= confidenceThreshold
            
            lastResult = accepted
            
            if prediction.expectsSpeakerChange {
                print("[SemanticAdvisor] Speaker change predicted " +
                      "(confidence: \(String(format: "%.0f%%", prediction.confidence * 100)), " +
                      "threshold: \(String(format: "%.0f%%", confidenceThreshold * 100)), " +
                      "accepted: \(accepted))")
            }
            
            return accepted
        } catch {
            // LLM errors are non-fatal; acoustic model handles it alone.
            print("[SemanticAdvisor] LLM error: \(error.localizedDescription)")
            lastResult = false
            return false
        }
    }
}
