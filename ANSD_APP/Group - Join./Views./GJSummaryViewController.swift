//  GJSummaryViewController.swift
//  ANSD_APP

import UIKit
import PDFKit
import Foundation
import FoundationModels // Required for Apple Intelligence

class GJSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GJNotesCardCellDelegate {
    
    @IBOutlet weak var GJtableView: UITableView!
    @IBOutlet weak var GJoptionsButton: UIBarButtonItem!
    
    var conversationTitle = "Session Summary"
    
    // NEW: Receive real messages from GroupJoinViewController
    var transcriptMessages: [GJChatMessage] = []
    
    // We will generate this list based on the transcript
    var participantsData: [GJParticipantData] = []
    
    // Stores the AI Summary
    private(set) var notesText: String = ""
    
    // Properties for on-device AI
    private let model = SystemLanguageModel.default
    private var isProcessing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
        // 1. Convert real messages into participant data for the UI
        if !transcriptMessages.isEmpty {
            prepareParticipantsFromMessages()
        }
        
        // 2. Generate summary from real text
        generateAISummary()
    }
    
    // MARK: - UI Configuration
    func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        GJtableView.delegate = self
        GJtableView.dataSource = self
        GJtableView.separatorStyle = .none
        GJtableView.backgroundColor = .clear
        GJtableView.rowHeight = UITableView.automaticDimension
        GJtableView.estimatedRowHeight = 120
        
        if let shareBtn = GJoptionsButton {
            shareBtn.target = self
            shareBtn.action = #selector(shareTapped)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Data Preparation
    private func prepareParticipantsFromMessages() {
        // Find unique senders to populate the list
        var uniqueSenders: [String: String] = [:] // [ID: Name]
        
        for msg in transcriptMessages {
            if uniqueSenders[msg.senderID] == nil {
                uniqueSenders[msg.senderID] = msg.sender
            }
        }
        
        // Create participant objects (Using dummy summary for individual rows for now)
        self.participantsData = uniqueSenders.map { (_, name) in
            GJParticipantData(
                name: name,
                summary: "Participant",
                //imageName: "avatar_1"
            )
        }
        
        self.GJtableView.reloadData()
    }

    // MARK: - AI Summarization Logic
    private func generateAISummary() {
        // 1. Prepare the raw transcript from REAL MESSAGES
        var rawTranscript = ""
        
        if !transcriptMessages.isEmpty {
            rawTranscript = transcriptMessages
                .map { "\($0.sender): \($0.text)" }
                .joined(separator: "\n")
        } else {
            rawTranscript = "No conversation data recorded."
        }

        guard !rawTranscript.isEmpty && rawTranscript != "No conversation data recorded." else {
            updateNotes("No conversation data available.")
            return
        }

        // 2. Check if the on-device model is available
        guard model.isAvailable else {
            updateNotes("AI Model unavailable. Raw Transcript:\n\n" + rawTranscript)
            return
        }

        updateNotes("Summarizing with Apple Intelligence...")
        isProcessing = true

        // 3. Run the model asynchronously
        Task {
            let prompt = """
            Summarize the following meeting transcript.

            Requirements:
            - Focus on key points, decisions, and action items.
            - Do not add information that is not in the transcript.
            - Keep it under 200 words.

            Format:
            Summary:
            - 3–6 bullet points.

            Decisions:
            - Bullet list of decisions, or “None noted.”

            Action Items:
            - “• [Owner] – [Task] – [Deadline if given]”, or “None noted.”

            Transcript:
            \(rawTranscript)
            """

            let session = LanguageModelSession()

            do {
                let response = try await session.respond(to: prompt)
                await MainActor.run {
                    self.isProcessing = false
                    self.updateNotes(response.content)
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.updateNotes("Failed to summarize. Showing raw transcript:\n\n" + rawTranscript)
                }
            }
        }
    }

    private func updateNotes(_ text: String) {
        notesText = text
        DispatchQueue.main.async {
            // Reload the Notes section (Section 5)
            self.GJtableView.reloadSections(IndexSet(integer: 5), with: .automatic)
        }
    }

    // MARK: - Export Logic
    @objc func shareTapped() {
        shareAsPDF()
    }
    
    @IBAction func backTapped(_ sender: Any) {
        if let navController = self.view.window?.rootViewController as? UINavigationController {
            navController.popToRootViewController(animated: false)
            navController.dismiss(animated: true, completion: nil)
        } else {
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func shareAsPDF() {
        var pdfContent = "Conversation Title: \(conversationTitle)\n\n"
        pdfContent += "--- AI SUMMARY ---\n\n"
        pdfContent += "\(notesText)\n\n" // Use the generated notes
        
        if !transcriptMessages.isEmpty {
            pdfContent += "--- FULL TRANSCRIPT ---\n\n"
            for msg in transcriptMessages {
                pdfContent += "\(msg.sender): \(msg.text)\n"
            }
        }
        
        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            
            // iPad support
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            self.present(activityVC, animated: true)
        }
    }
    
    func createPDF(from text: String) -> URL? {
        let pageWidth = 595.2
        let pageHeight = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let attributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
                NSAttributedString.Key.paragraphStyle: NSMutableParagraphStyle()
            ]
            let textRect = CGRect(x: 40, y: 40, width: pageWidth - 80, height: pageHeight - 80)
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        let tempFolder = FileManager.default.temporaryDirectory
        let fileName = "Session_Summary.pdf"
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
        if section == 3 { return participantsData.count }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GJSummarySectionHeaderCell
                cell.headerLabel.text = "Conversation Summary"
                cell.headerIcon.image = UIImage(systemName: "list.bullet.clipboard")
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! GJSummaryCardCell
                cell.titleLabel.text = conversationTitle
                return cell
            case 2:
                return tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath)
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! GJParticipantCardCell
                let data = participantsData[indexPath.row]
                cell.configure(with: data)
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GJSummarySectionHeaderCell
                cell.headerLabel.text = "AI Notes"
                cell.headerIcon.image = UIImage(systemName: "note.text")
                return cell
            case 5:
                let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! GJNotesCardCell
                
                // FIX: Changed 'GJnotesTextView' to 'notesTextView'
                cell.notesTextView.text = notesText
                
                // FIX: This error will vanish once the line above is fixed
                cell.notesTextView.textColor = isProcessing ? .secondaryLabel : .label
                
                cell.delegate = self
                return cell
            default:
                return UITableViewCell()
            }
        }
        
        func didUpdateText(in cell: GJNotesCardCell) {
            // FIX: Changed 'GJnotesTextView' to 'notesTextView'
            notesText = cell.notesTextView.text
            
            GJtableView.performBatchUpdates(nil, completion: nil)
            if let indexPath = GJtableView.indexPath(for: cell) {
                GJtableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
}
