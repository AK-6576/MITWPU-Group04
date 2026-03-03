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
    private let delay: TimeInterval = 0.3
    
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
        Fix the grammar, punctuation, and capitalization of the following text, but keep the tone natural and conversational. Do not add any extra commentary.
        
        Text: "\(text)"
        """
        
        let session = LanguageModelSession(model: model)
        
        do {
            let response = try await session.respond(to: prompt)
            
            await MainActor.run {
                completion(index, response.content)
            }
        } catch {
            print("❌ AI Cleanup Error: \(error)")
        }
    }
    
    func cancelAllPendingTasks() {
        workItems.values.forEach { $0.cancel() }
        workItems.removeAll()
    }
}
