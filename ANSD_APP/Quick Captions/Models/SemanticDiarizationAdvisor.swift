//
//  SemanticDiarizationAdvisor.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import FoundationModels

@available(iOS 18.1, *)
final class SemanticDiarizationAdvisor {
    
    // MARK: - Structured Output
    
    @Generable
    struct Prediction {
        @Guide(description: "True if the next utterance is likely from a different speaker based on conversation flow.")
        var expectsSpeakerChange: Bool
    }
    
    // MARK: - State
    
    private var context: [(speaker: String, text: String)] = []
    private let maxContext = 6
    
    // MARK: - Public API
    
    /// Records an utterance to the rolling context window for semantic analysis.
    func record(speaker: String, text: String) {
        context.append((speaker: speaker, text: text))
        if context.count > maxContext { context.removeFirst() }
    }
    
    /// Uses on-device LLM to predict if a speaker change is imminent.
    func predictSpeakerChange() async -> Bool {
        guard SystemLanguageModel.default.isAvailable, context.count >= 2 else { return false }
        
        let dialogue = context
            .map { "[\($0.speaker)]: \($0.text)" }
            .joined(separator: "\n")
        
        let prompt = """
        Analyze the conversation context below and predict if the NEXT utterance will be from a DIFFERENT speaker.
        
        Context:
        \(dialogue)
        
        Rules:
        - Return change=true for questions awaiting answers or topic hand-offs.
        - Return change=false if the last speaker is likely to continue their thought.
        """
        
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt, generating: Prediction.self)
            let result = response.content.expectsSpeakerChange
            if result {
                print("🧠 [SemanticAdvisor] Speaker change predicted from context!")
            }
            return result
        } catch {
            print("❌ [SemanticAdvisor] Warning: Prediction failed: \(error)")
            return false
        }
    }
}
