//
//  TextCleanupManager.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation
import FoundationModels // Apple Intelligence Framework

class TextCleanupManager {
    
    // MARK: - Properties
    private let model = SystemLanguageModel.default
    private var workItems: [Int: DispatchWorkItem] = [:]
    
    // CHANGED: 1.0 second delay after stopping speaking
    private let delay: TimeInterval = 1.0
    
    // MARK: - API
    
    func scheduleCleanup(text: String, at index: Int, completion: @escaping (Int, String) -> Void) {
        
        workItems[index]?.cancel()
        
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            Task {
                await self.performAIProcessing(text: text, index: index, completion: completion)
            }
            
            DispatchQueue.main.async {
                self.workItems.removeValue(forKey: index)
            }
        }
        
        workItems[index] = item
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay, execute: item)
    }
    
    // MARK: - Private AI Logic
    
    private func performAIProcessing(text: String, index: Int, completion: @escaping (Int, String) -> Void) async {
        guard !text.isEmpty, text.count > 3 else { return }
        guard model.isAvailable else { return }
        
        let prompt = """
        Fix grammar and punctuation in the conversational text below. The text may be in any language.
        Rules:
        - Return the corrected text EXACTLY ONCE.
        - Do NOT wrap the output in quotation marks of any kind.
        - Do NOT repeat or duplicate the text.
        - Do NOT add commentary, explanations, apologies, or any surrounding words.
        - If the input is empty or unintelligible, return it unchanged — nothing else.

        Text: \(text)
        """
        
        let session = LanguageModelSession(model: model)
        
        do {
            let response = try await session.respond(to: prompt)
            var cleanedText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Strip wrapping quotation marks (straight, curly, or double) that AI may add
            let quoteChars: Set<Character> = ["\"", "\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}"]
            if let first = cleanedText.first, let last = cleanedText.last,
               quoteChars.contains(first) && quoteChars.contains(last) && cleanedText.count > 2 {
                cleanedText = String(cleanedText.dropFirst().dropLast())
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Safety filter 1: Reject known AI boilerplate
            let boilerplatePrefixes = ["i'm sorry", "as a language model", "as an ai", "i cannot process"]
            let lowercaseResponse = cleanedText.lowercased()
            let isBoilerplate = boilerplatePrefixes.contains { prefix in
                lowercaseResponse.hasPrefix(prefix) || (lowercaseResponse.contains(prefix) && cleanedText.count < 30)
            }
            
            // Safety filter 2: Reject if response is more than 2x the length of the input (likely a duplication)
            let isDuplicated = cleanedText.count > (text.count * 2 + 20)
            
            if isBoilerplate || isDuplicated {
                cleanedText = text
            }
            
            await MainActor.run {
                completion(index, cleanedText)
            }
        } catch {
            print("Error: AI Cleanup Error: \(error)")
        }
    }
    
    func cancelAllPendingTasks() {
        workItems.values.forEach { $0.cancel() }
        workItems.removeAll()
    }
}
