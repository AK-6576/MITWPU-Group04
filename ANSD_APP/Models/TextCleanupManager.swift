//
//  TextCleanupManager.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import Foundation

#if canImport(FoundationModels) && !targetEnvironment(simulator)
import FoundationModels
#endif

class TextCleanupManager {
    
    // MARK: - Properties
    
    #if !targetEnvironment(simulator)
    private let model = SystemLanguageModel.default
    #endif
    private var workItems: [Int: DispatchWorkItem] = [:]
    
    /// Delay before triggering AI processing to allow for mid-sentence corrections.
    private let processingDelay: TimeInterval = 0.4
    
    // MARK: - API
    
    /// Schedules an AI-based cleanup for the given text.
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
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + processingDelay, execute: item)
    }
    
    func cancelAllPendingTasks() {
        workItems.values.forEach { $0.cancel() }
        workItems.removeAll()
    }
    
    // MARK: - Private Logic
    
    private func performAIProcessing(text: String, index: Int, completion: @escaping (Int, String) -> Void) async {
        guard !text.isEmpty, text.count > 3 else { return }

        #if targetEnvironment(simulator)
        // Simulator fallback
        await MainActor.run { completion(index, text) }
        #else
        guard model.isAvailable else {
            print("[TextCleanup] Warning: FoundationModels not available.")
            await MainActor.run { completion(index, text) }
            return
        }
        
        let prompt = """
        Clean up the following conversational text by fixing grammar and punctuation.
        Return ONLY the cleaned text in the SAME language as the input.
        DO NOT add any commentary or explanations.
        
        Text: "\(text)"
        """
        
        do {
            let session = LanguageModelSession(model: model)
            let response = try await session.respond(to: prompt)
            var cleanedText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Boilerplate detection
            let lower = cleanedText.lowercased()
            if lower.contains("as an ai") || lower.contains("i'm sorry") || lower.contains("cannot process") {
                cleanedText = text
            }
            
            await MainActor.run {
                completion(index, cleanedText)
            }
        } catch {
            print("[TextCleanup] Error: AI cleanup failed: \(error.localizedDescription)")
            await MainActor.run { completion(index, text) }
        }
        #endif
    }
}
