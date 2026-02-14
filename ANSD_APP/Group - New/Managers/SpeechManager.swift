import Foundation
import Speech

class SpeechManager: NSObject {
    // 1. Change to optional 'var' so we can re-initialize it with different languages
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // 2. Added languageCode parameter (e.g., "en-US", "hi-IN", "es-ES")
    func startTranscribing(languageCode: String, completion: @escaping (String) -> Void) {
        
        // 3. Initialize with the chosen language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode))
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Error: Language \(languageCode) is not supported on this device.")
            return
        }

        recognitionTask?.cancel()
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        recognitionRequest?.shouldReportPartialResults = true
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                completion(transcribedText)
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    func stopTranscribing() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
}
