//
//  SummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import PDFKit
import FoundationModels
import FirebaseAuth

class SummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, QuickCaptionsNotesCardCellDelegate, QuickCaptionsSummaryCardDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    // MARK: - Data Input
    
    var conversationTitle = "Conversation 1"
    var rawTranscriptText: String = ""
    var rawMessages: [QuickCaptionsChat] = []
    var participantsData: [QuickCaptionsParticipantData] = []
    
    var dateString: String = ""
    var timeString: String = ""
    var locationString: String = ""
    
    // MARK: - AI Pipeline State
    
    private let model = SystemLanguageModel.default
    private var isProcessing = false
    private var notesContent: String = "Generating session summary..."
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
    }
    
    // MARK: - Actions
    
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        generateAndSharePDF()
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.view.endEditing(true)
        self.saveSessionToHistory()
        // Return to Home Storyboard
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
    
    private func saveSessionToHistory() {
        let convoID = UUID().uuidString
        let newConvo = Conversation(
            id: convoID,
            title: conversationTitle,
            details: "Session summary and transcript",
            date: dateString,
            startTime: timeString,
            endTime: "", // Could be calculated if needed
            location: locationString,
            calendarDate: Date(),
            notes: notesContent
        )
        
        // 1. Save Participants
        var savedParticipants: [Participant] = []
        for p in participantsData {
            let participant = Participant(name: p.name, summary: p.summary, image: "")
            participant.conversation = newConvo
            savedParticipants.append(participant)
        }
        newConvo.participants = savedParticipants
        
        // 2. Save Messages
        var savedMessages: [Message] = []
        for m in rawMessages {
            let msg = Message(
                id: UUID(),
                text: m.text,
                senderId: m.senderID,
                senderName: m.sender,
                isIncoming: m.isIncoming,
                timestamp: m.timestamp ?? Date()
            )
            msg.conversation = newConvo
            savedMessages.append(msg)
        }
        newConvo.messages = savedMessages
        
        // 3. Persist via DataManager
        DataManager.shared.addConversation(newConvo)
        print("[SummaryView] Successfully saved session \(convoID) to history.")
    }
    
    func didUpdateText(in cell: QuickCaptionsNotesCardCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
        if let text = cell.notesTextView.text {
            notesContent = text
        }
    }
    
    func didChangeTitle(text: String) {
        conversationTitle = text
    }
    
    // MARK: - AI Analysis
    
    private func generateAISummary() {
        guard !isProcessing else { return }
        isProcessing = true
        notesContent = "Analyzing conversation flow..."
        tableView.reloadData()
        
        Task {
            do {
                let phase1Result = try await runPhase1(transcript: rawTranscriptText)
                let parsed = parsePhase1(phase1Result)
                
                applyGhostMerges(parsed.ghostMappings)
                
                await withThrowingTaskGroup(of: (String, String).self) { group in
                    for participant in participantsData {
                        let lines = buildSpeakerLines(for: participant.name)
                        guard !lines.isEmpty else { continue }
                        group.addTask {
                            let summary = try await self.runSpeakerAnalysis(name: participant.name, lines: lines)
                            return (participant.name, summary)
                        }
                    }
                    while let (name, summary) = try? await group.next() {
                        if let idx = participantsData.firstIndex(where: { $0.name == name }) {
                            participantsData[idx].summary = summary
                        }
                    }
                }
                
                await MainActor.run {
                    self.notesContent = parsed.notes
                    self.isProcessing = false
                    self.tableView.reloadData()
                }
            } catch {
                print("[SummaryView] Error: AI Pipeline failed: \(error)")
                await MainActor.run {
                    self.notesContent = "Summary generation failed."
                    self.isProcessing = false
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func runPhase1(transcript: String) async throws -> String {
        #if targetEnvironment(simulator)
        return "GHOST_MERGES:\nNone\n\nNOTES:\nSummary unavailable in Simulator mode. Please test on a physical device with Apple Intelligence."
        #else
        let prompt = "Analyze the transcript and provide GHOST_MERGES and NOTES sections.\n\nTRANSCRIPT:\n\(transcript)"
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: prompt)
        return response.content
        #endif
    }
    
    private func runSpeakerAnalysis(name: String, lines: String) async throws -> String {
        #if targetEnvironment(simulator)
        return "Simulated summary for \(name)."
        #else
        let prompt = "Summarize \(name)'s points in 3-5 sentences:\n\(lines)"
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        #endif
    }
    
    private func parsePhase1(_ text: String) -> (ghostMappings: [String: String], notes: String) {
        var mappings: [String: String] = [:]
        var notes = ""
        let sections = text.components(separatedBy: "NOTES:")
        if sections.count >= 2 {
            notes = sections[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let ghostLines = sections[0].components(separatedBy: .newlines)
            for line in ghostLines where line.contains("=") {
                let parts = line.components(separatedBy: "=")
                if parts.count == 2 {
                    mappings[parts[0].trimmingCharacters(in: .whitespacesAndNewlines)] = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return (mappings, notes.isEmpty ? "No notes generated." : notes)
    }
    
    private func buildSpeakerLines(for name: String) -> String {
        return rawMessages.filter { $0.sender == name }.map { $0.text }.joined(separator: "\n")
    }
    
    private func applyGhostMerges(_ mappings: [String: String]) {
        for (ghost, real) in mappings {
            if let ghostIdx = participantsData.firstIndex(where: { $0.name == ghost }) {
                participantsData.remove(at: ghostIdx)
            }
        }
    }
    
    // MARK: - TableView (Restored 5-Section Layout)
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 { return participantsData.count }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // Conversation Header
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QuickCaptionsSummarySectionHeaderCell
            cell.headerLabel?.text = "Conversation Summary"
            cell.headerIcon?.image = UIImage(systemName: "clipboard.fill")
            return cell
            
        case 1: // Main Header Card
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! QuickCaptionsSummaryCardCell
            cell.configure(title: conversationTitle, date: dateString, time: timeString, location: locationString)
            cell.delegate = self
            return cell
            
        case 2: // Participant Section Header
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QuickCaptionsSummarySectionHeaderCell
            cell.headerLabel?.text = "Participant Summary"
            cell.headerIcon?.image = UIImage(systemName: "person.2.fill")
            return cell
            
        case 3: // Participant Cards
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCardCell", for: indexPath) as! QuickCaptionsParticipantCardCell
            cell.configure(with: participantsData[indexPath.row])
            return cell
            
        case 4: // Notes Section Header
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QuickCaptionsSummarySectionHeaderCell
            cell.headerLabel?.text = "Notes"
            cell.headerIcon?.image = UIImage(systemName: "list.bullet.clipboard")
            return cell
            
        case 5: // Notes Card
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! QuickCaptionsNotesCardCell
            cell.notesTextView?.text = notesContent
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    private func generateAndSharePDF() {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: 612, height: 792), nil)
        UIGraphicsBeginPDFPage()
        let titleAttr = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        "Summary: \(conversationTitle)".draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttr)
        let bodyAttr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
        rawTranscriptText.draw(in: CGRect(x: 50, y: 100, width: 512, height: 600), withAttributes: bodyAttr)
        UIGraphicsEndPDFContext()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Transcript.pdf")
        try? pdfData.write(to: tempURL)
        present(UIActivityViewController(activityItems: [tempURL], applicationActivities: nil), animated: true)
    }
}
