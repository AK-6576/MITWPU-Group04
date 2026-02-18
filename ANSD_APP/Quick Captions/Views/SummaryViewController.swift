//
//  SummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import PDFKit
import FoundationModels // Apple Intelligence

class SummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, QuickCaptionsNotesCardCellDelegate, QuickCaptionsSummaryCardDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    // MARK: - Data Sources
    var conversationTitle = "Conversation 1"
    var rawTranscriptText: String = ""
    var participantsData: [QuickCaptionsParticipantData] = []
    
    // MARK: - Header Data
    var dateString: String = ""
    var timeString: String = ""
    var locationString: String = ""
    
    // MARK: - AI State
    private let model = SystemLanguageModel.default
    private var isProcessing = false
    private var notesContent: String = "Generating summary..."
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground
        
        guard tableView != nil else {
            print("❌ CRITICAL: TableView is not connected in Storyboard")
            return
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        // Connect Share Button
        if let shareBtn = shareButton {
            shareBtn.target = self
            shareBtn.action = #selector(shareButtonTapped)
        }
        
        // Dismiss Keyboard Gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        generateAISummary()
    }
    
    // MARK: - AI Logic
    private func generateAISummary() {
        guard !rawTranscriptText.isEmpty else {
            self.notesContent = "No transcript available."
            self.tableView.reloadData()
            return
        }
        
        isProcessing = true
        self.tableView.reloadData()
        
        Task {
            do {
                // 1. Dynamically build instructions for EVERY participant in the list
                var participantPrompts = ""
                for person in participantsData {
                    // Create a clean tag (e.g., PETER_PARKER)
                    let safeName = person.name.replacingOccurrences(of: " ", with: "_").uppercased()
                    participantPrompts += """
                    Step: Write a section strictly labeled "PARTICIPANT_\(safeName):" summarizing what \(person.name) said in their own perspective using the third person (e.g., "\(person.name) believes that...").
                    
                    """
                }
                
                let prompt = """
                Analyze the following transcript.
                
                Step 1: Write a section strictly labeled "NOTES:" containing bullet points of action items, key takeaways, and dates mentioned.
                
                \(participantPrompts)
                
                TRANSCRIPT:
                \(rawTranscriptText)
                """
                
                let session = LanguageModelSession(model: model)
                let response = try await session.respond(to: prompt)
                
                await MainActor.run {
                    self.parseAIResponse(response.content)
                    self.isProcessing = false
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.notesContent = "Could not generate summary. Error: \(error.localizedDescription)"
                    self.isProcessing = false
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func parseAIResponse(_ text: String) {
        let components = text.components(separatedBy: CharacterSet.newlines)
        
        var currentSection = ""
        var notesBuffer = ""
        
        // 2. Create buffers for each participant
        var participantBuffers: [String: String] = [:]
        for person in participantsData {
            let safeName = person.name.replacingOccurrences(of: " ", with: "_").uppercased()
            participantBuffers[safeName] = ""
        }
        
        for line in components {
            // Check for Notes Header
            if line.contains("NOTES:") {
                currentSection = "NOTES"
                continue
            }
            
            // Check for Participant Headers Dynamically
            var isParticipantHeader = false
            for person in participantsData {
                let safeName = person.name.replacingOccurrences(of: " ", with: "_").uppercased()
                if line.contains("PARTICIPANT_\(safeName):") {
                    currentSection = safeName
                    isParticipantHeader = true
                    break
                }
            }
            if isParticipantHeader { continue }
            
            // Append content to the active section
            if currentSection == "NOTES" {
                notesBuffer += line + "\n"
            } else if participantBuffers[currentSection] != nil {
                participantBuffers[currentSection]? += line + "\n"
            }
        }
        
        // 3. Update Notes
        self.notesContent = notesBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.notesContent.isEmpty { self.notesContent = text }
        
        // 4. Update Participants Data
        for i in 0..<participantsData.count {
            let person = participantsData[i]
            let safeName = person.name.replacingOccurrences(of: " ", with: "_").uppercased()
            
            if let summary = participantBuffers[safeName], !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                participantsData[i].summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                participantsData[i].summary = "No summary available."
            }
        }
    }
    
    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func backTapped(_ sender: Any) {
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
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        shareAsPDF()
    }
    
    // MARK: - PDF Generation
    private func shareAsPDF() {
        var pdfContent = "Conversation Title: \(conversationTitle)\n"
        pdfContent += "\(dateString) | \(timeString) | \(locationString)\n\n"
        
        pdfContent += "--- NOTES ---\n"
        pdfContent += "\(notesContent)\n\n"
        
        pdfContent += "--- PARTICIPANTS ---\n"
        for person in participantsData {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }
        
        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            self.present(activityVC, animated: true)
        }
    }
    
    private func createPDF(from text: String) -> URL? {
        let pageWidth = 595.2
        let pageHeight = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: NSMutableParagraphStyle()
            ]
            let textRect = CGRect(x: 40, y: 40, width: pageWidth - 80, height: pageHeight - 80)
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        let tempFolder = FileManager.default.temporaryDirectory
        let fileName = "\(conversationTitle) - Summary.pdf"
        let fileURL = tempFolder.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error generating PDF: \(error)")
            return nil
        }
    }

    // MARK: - TableView Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1, 2: return 1
        case 3: return participantsData.count
        case 4, 5: return 1
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
            
        // MARK: SECTION 0 - Header: "Conversation Summary"
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QuickCaptionsSummarySectionHeaderCell
            cell.headerLabel.text = "Conversation Summary"
            cell.headerIcon.image = UIImage(systemName: "list.clipboard")
            cell.selectionStyle = .none
            return cell
            
        // MARK: SECTION 1 - Card: Date, Time, Location
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! QuickCaptionsSummaryCardCell
            
            // ✅ Configure Data
            cell.configure(
                title: self.conversationTitle,
                date: self.dateString,
                time: self.timeString,
                location: self.locationString
            )
            // ✅ Connect Delegate for Title Changes
            cell.delegate = self
            
            cell.selectionStyle = .none
            return cell
            
        // MARK: SECTION 2 - Header: "Participants Summary"
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QuickCaptionsSummarySectionHeaderCell
            // Updated to match Figma text
            cell.headerLabel.text = "Participants Summary"
            cell.headerIcon.image = UIImage(systemName: "person.2.fill")
            cell.selectionStyle = .none
            return cell
            
        // MARK: SECTION 3 - List: Participant Rows
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCardCell", for: indexPath) as! QuickCaptionsParticipantCardCell
            let participant = participantsData[indexPath.row]
            
            // ✅ Configure Data
            cell.configure(with: participant)
            
            cell.selectionStyle = .none
            return cell
            
        // MARK: SECTION 4 - Header: "Notes"
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QuickCaptionsSummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            cell.selectionStyle = .none
            return cell
            
        // MARK: SECTION 5 - Card: Key Takeaways
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! QuickCaptionsNotesCardCell
            cell.notesTextView.text = self.notesContent
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - Delegates
    func didUpdateText(in cell: QuickCaptionsNotesCardCell) {
        self.notesContent = cell.notesTextView.text
        tableView.performBatchUpdates(nil, completion: nil)
        
        if let indexPath = tableView.indexPath(for: cell) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func didChangeTitle(text: String) {
        self.conversationTitle = text
    }
}
