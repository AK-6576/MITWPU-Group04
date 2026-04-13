//
//  SemanticDiarizationAdvisor.swift
//  ANSD_APP
//
//  Created by Antigravity on 26/03/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//
//  Uses Apple Intelligence (FoundationModels, on-device LLM) to predict
//  speaker-change points from *conversational context* — things the acoustic
//  VL1004 model cannot know, such as question-answer pairs, topic hand-offs,
//  or pronoun shifts.  Runs fully on-device; no network, no privacy risk.
//
//  Availability: iOS 18.1+ with Apple Intelligence enabled.
//  The rest of the app degrades gracefully when unavailable.
//

import Foundation
import FoundationModels

@available(iOS 18.1, *)
final class SemanticDiarizationAdvisor {
    
    // MARK: - Structured Output
    
    /// The single boolean the LLM returns per prediction call.
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
    }
    
    // MARK: - State
    
    private lazy var session = LanguageModelSession()
    private var context: [(speaker: String, text: String)] = []
    private let maxContext = 6   // last 6 utterances ≈ 30–60 s of conversation
    
    // MARK: - Public API
    
    /// Append a finalised utterance to the rolling context window.
    func record(speaker: String, text: String) {
        context.append((speaker: speaker, text: text))
        if context.count > maxContext { context.removeFirst() }
    }
    
    /// Predict whether the next utterance will come from a different speaker.
    /// Returns `false` immediately when Apple Intelligence is unavailable or
    /// context is too thin (< 2 utterances).
    func predictSpeakerChange() async -> Bool {
#if targetEnvironment(simulator)
        print("⚠️ [SemanticAdvisor] Bypassed Apple Intelligence on Simulator to prevent FoundationModels EXC_BREAKPOINT.")
        return false
#else
        guard SystemLanguageModel.default.isAvailable,
              context.count >= 2 else { return false }
        
        let dialogue = context
            .map { "[\($0.speaker)]: \($0.text)" }
            .joined(separator: "\n")
        
        let prompt = """
        You are a real-time conversation-turn detector embedded in a \
        captioning app for people with hearing loss. Analyse the dialogue \
        below and predict whether the NEXT utterance will come from a \
        DIFFERENT speaker than the last one shown.
        
        Conversation so far:
        \(dialogue)
        
        Rules:
        - Predict change=true for unanswered questions, reply starters, \
          or clear topic hand-offs.
        - Predict change=false when the last speaker is continuing a \
          thought, listing items, or narrating.
        - When in doubt, predict false (acoustic model is the primary signal).
        """
        
        do {
            let response = try await session.respond(to: prompt,
                                                     generating: Prediction.self)
            let result = response.content.expectsSpeakerChange
            if result {
                print("🧠 [SemanticAdvisor] Speaker change predicted by Apple Intelligence")
            }
            return result
        } catch {
            // LLM errors are non-fatal; acoustic model handles it alone.
            return false
        }
#endif
    }
}
