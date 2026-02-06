import Foundation
import Speech
import AVFoundation

class SpeechManager: NSObject {
    // MARK: - Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Stored property to keep track of text for the return value
    private var latestTranscribedText: String = ""

    // MARK: - Methods
    
    /// Starts the transcription process for a specific language.
    /// - Parameters:
    ///   - languageCode: The BCP-47 identifier (e.g., "en-US").
    ///   - completion: A closure that returns partial results as the user speaks.
    func startTranscribing(languageCode: String, completion: @escaping (String) -> Void) {
        
        // 1. Reset state and clean up previous attempts
        latestTranscribedText = ""
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 2. Initialize with the chosen language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode))
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("❌ Error: Language \(languageCode) is not supported or recognizer is unavailable.")
            return
        }

        // 3. Configure Audio Session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio Session Error: \(error.localizedDescription)")
        }

        // 4. Create Recognition Request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        // 5. Setup Input Node and Safety: Remove existing tap before adding a new one
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        // 6. Start Recognition Task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                // Store the result so it can be returned by stopTranscribing()
                let transcribedText = result.bestTranscription.formattedString
                self.latestTranscribedText = transcribedText
                completion(transcribedText)
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        // 7. Install Audio Tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // 8. Start Engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("❌ Audio Engine could not start: \(error.localizedDescription)")
        }
    }
    
    /// Stops the transcription and returns the final captured string.
    /// - Returns: The final formatted transcription string.
    func stopTranscribing() -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0) // Clean up audio
        recognitionRequest?.endAudio()
        
        // Return the accumulated text to the ViewController
        let finalResult = latestTranscribedText
        
        // Optional: Keep recognitionTask active for a moment to catch final fragments
        // or cancel it if you want an immediate hard stop.
        recognitionTask?.cancel()
        
        return finalResult
    }
}
