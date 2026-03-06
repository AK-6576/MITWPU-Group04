//
//  ActionSummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import PDFKit
import FoundationModels // Apple Intelligence

// MARK: - Required Structs for AI JSON Parsing
struct AISummaryResponse: Codable {
    let notes: String
    let participants: [AIParticipantSummary]
}

struct AIParticipantSummary: Codable {
    let name: String
    let summary: String
}


// MARK: - Summary Base Class
class BaseSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotesCardCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    
    // MARK: - Properties
    var category: String = "Family" {
        didSet {
            self.title = "\(category) Summary"
        }
    }
    
    var conversationTitle = "Conversation Summary"
    var participants: [ParticipantData] = []
    
    // MARK: - AI & State Properties
    var transcriptMessages: [ChatMessage] = [] // Pass this in before pushing the VC
    private let model = SystemLanguageModel.default
    private var isProcessing = false
    private(set) var notesText: String = "Generating summary..."
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "\(category) Summary"
        setupUI()
        
        // 1. Initial Data Prep
        if !transcriptMessages.isEmpty {
            prepareParticipantsFromMessages()
        }
        
        // 2. Start AI Analysis
        generateAISummary()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        optionsButton?.target = self
        optionsButton?.action = #selector(shareTapped)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() { view.endEditing(true) }
    @objc func shareTapped() { shareAsPDF() }
    
    @IBAction func backTapped(_ sender: Any) {
        self.saveSessionToHistory()
        
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "Home")
        let navController = UINavigationController(rootViewController: homeVC)
        navController.isNavigationBarHidden = false
        navController.modalPresentationStyle = .fullScreen
        if let window = self.view.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = navController
            }, completion: nil)
            window.makeKeyAndVisible()
        }
    }
    
    // MARK: - Data Preparation
    private func prepareParticipantsFromMessages() {
        var seenSenders = Set<String>()
        var ordering: [String] = []
        
        for msg in transcriptMessages {
            if !seenSenders.contains(msg.sender) {
                seenSenders.insert(msg.sender)
                ordering.append(msg.sender)
            }
        }
        
        // Initialize with waiting state
        self.participants = ordering.map { name in
            ParticipantData(name: name, summary: "Waiting for analysis...")
        }
        tableView.reloadData()
    }
    
    // MARK: - AI Foundation Models Integration
    private func generateAISummary() {
        guard !transcriptMessages.isEmpty else {
            self.notesText = "No conversation to summarize."
            self.tableView.reloadData()
            return
        }
        
        isProcessing = true
        let fullTranscript = transcriptMessages.map { "\($0.sender): \($0.text)" }.joined(separator: "\n")
        
        Task {
            do {
                // Strict JSON Prompt
                let prompt = """
                Analyze the following transcript. You must respond ONLY with a raw, valid JSON object. Do not include markdown blocks, explanations, or code tags.
                
                The JSON must perfectly match this structure:
                {
                  "notes": "A bulleted string of action items and key takeaways.",
                  "participants": [
                    { "name": "Participant Name", "summary": "A short third-person summary of what they said." }
                  ]
                }
                
                TRANSCRIPT:
                \(fullTranscript)
                """
                
                let session = LanguageModelSession(model: model)
                let response = try await session.respond(to: prompt)
                
                await MainActor.run {
                    self.parseJSONResponse(response.content)
                }
                
            } catch {
                await MainActor.run {
                    self.notesText = "Could not generate summary. Error: \(error.localizedDescription)"
                    self.isProcessing = false
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func parseJSONResponse(_ text: String) {
        // 1. Clean up the response in case the LLM wrapped it in markdown code blocks anyway
        var cleanJSONString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanJSONString.hasPrefix("```json") {
            cleanJSONString = cleanJSONString.replacingOccurrences(of: "```json", with: "")
            cleanJSONString = cleanJSONString.replacingOccurrences(of: "```", with: "")
        }
        
        guard let jsonData = cleanJSONString.data(using: .utf8) else {
            self.notesText = "Failed to parse AI response into data."
            self.isProcessing = false
            self.tableView.reloadData()
            return
        }
        
        // 2. Safely Decode
        do {
            let decodedSummary = try JSONDecoder().decode(AISummaryResponse.self, from: jsonData)
            
            // Assign Notes
            self.notesText = decodedSummary.notes
            
            // Assign Participant Summaries by matching names
            for aiParticipant in decodedSummary.participants {
                if let index = self.participants.firstIndex(where: { aiParticipant.name.contains($0.name) || $0.name.contains(aiParticipant.name) }) {
                    self.participants[index].summary = aiParticipant.summary
                }
            }
            
            self.isProcessing = false
            self.tableView.reloadData()
            
        } catch {
            self.notesText = "Failed to decode JSON. Error: \(error.localizedDescription)"
            self.isProcessing = false
            self.tableView.reloadData()
        }
    }
    
    // MARK: - PDF Generation
    func shareAsPDF() {
        var pdfContent = "EchoWave Summary\n"
        pdfContent += "Category: \(category)\n"
        pdfContent += "---------------------------\n\n"
        
        pdfContent += "NOTES:\n\(notesText)\n\n"
        
        for person in participants {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }

        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            present(activityVC, animated: true)
        }
    }
    
    private func createPDF(from text: String) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8))
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
            text.draw(in: CGRect(x: 40, y: 40, width: 515.2, height: 761.8), withAttributes: attributes)
        }
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("Summary.pdf")
        try? data.write(to: fileURL)
        return fileURL
    }

    // MARK: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int { return 6 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 3 ? participants.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! SummarySectionHeaderCell
            cell.headerLabel.text = "Analysis"
            cell.headerIcon.image = UIImage(systemName: "sparkles")
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! SummaryCardCell
            cell.titleLabel.text = conversationTitle
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath) as! ParticipantsSummaryHeaderCell
            cell.participantLabel.text = "Participants"
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! ParticipantCardCell
            cell.configure(with: participants[indexPath.row])
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! SummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! NotesCardCell
            cell.notesTextView.text = self.notesText // Link the generated notes here
            cell.delegate = self
            return cell
        default: return UITableViewCell()
        }
    }
    
    func didUpdateText(in cell: NotesCardCell) {
        notesText = cell.notesTextView.text
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    // MARK: - Save to History
    private func saveSessionToHistory() {
        // 1. Map Participants to History Format
        let historyParticipants: [Participant] = participants.map { person in
            Participant(name: person.name, summary: person.summary, image: "person.circle.fill")
        }
        
        // 2. Map Transcript back into standard Message Bubbles
        let historyMessages: [Message] = transcriptMessages.map { msg in
            Message(
                id: UUID(),
                text: msg.text,
                senderId: msg.sender,
                senderName: msg.sender,
                isIncoming: msg.isIncoming,
                timestamp: Date(),
                isHighlighted: false,
                isEdited: false
            )
        }
        
        // 3. Grab the AI notes and format for the 1-2 liner description
        let finalNotes = self.notesText == "Generating summary..." ? "No notes generated." : self.notesText
        let cleanOneLiner = finalNotes.replacingOccurrences(of: "\n", with: " ")
        
        // 4. Package everything into a Conversation Object
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: now)
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: now)

        let newConversation = Conversation(
            id: UUID().uuidString,
            title: self.conversationTitle,
            details: cleanOneLiner,
            date: dateString,
            startTime: timeString,
            endTime: timeString,
            location: "Location Unknown",
            category: self.category,
            icon: "bolt.fill",
            info: nil,
            calendarDate: now,
            notes: finalNotes,
            isPinned: false,
            participants: historyParticipants,
            messages: historyMessages
        )
        
        // 5. Send to DataManager
        DataManager.shared.addConversation(newConversation)
        print("✅ Success: Saved Action session '\\(self.conversationTitle)' to History!")
    }
}

// MARK: - Storyboard Aliases
typealias ActionSummaryViewController = BaseSummaryViewController
typealias FriendsSummaryViewController = BaseSummaryViewController
typealias OfficeSummaryViewController = BaseSummaryViewController
