//
//  SummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import PDFKit
import FoundationModels // Required for Apple Intelligence

class SummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, QCNotesCardCellDelegate, QCSummaryCardDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    
    var conversationTitle = "Conversation 1"
    var participantsData: [QCParticipantData] = []
    
    // MARK: - AI Properties
    // This receives the text from the QuickCaptioningVC
    var rawTranscript: String = ""
    private var notesText: String = ""
    private var isProcessing = false
    
    // Apple Intelligence Model
    private let model = SystemLanguageModel.default
    
    // Function - Initializes the view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        if let shareBtn = optionsButton {
            shareBtn.target = self
            shareBtn.action = #selector(shareTapped)
        } else {
            print("WARNING: optionsButton is nil. Check Storyboard connection.")
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Trigger AI Summarization immediately
        generateAISummary()
    }
    
    // MARK: - Apple Intelligence Logic
    
    private func generateAISummary() {
        guard !rawTranscript.isEmpty else { return }
        
        // Safety check for device support
        guard model.isAvailable else {
            self.notesText = "AI Model unavailable on this device.\n\nRaw Transcript:\n\(rawTranscript)"
            self.tableView.reloadSections(IndexSet(integer: 5), with: .automatic)
            return
        }

        isProcessing = true
        // Set placeholder text
        self.notesText = "Apple Intelligence is analyzing the conversation..."
        self.tableView.reloadData()
        
        Task {
            let prompt = """
            You are an helpful assistant. Read this chat transcript.
            
            Task:
            1. Summarize the conversation.
            2. Extract key entities (Names, Codes, Money/Prices).
            
            Transcript:
            \(rawTranscript)
            
            Format:
            Summary: [Your summary]
            Details:
            - Codes: [List codes]
            - Cost: [List prices]
            """

            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                
                await MainActor.run {
                    self.isProcessing = false
                    self.notesText = response.content
                    self.updateNotesTable()
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.notesText = "Summary failed: \(error.localizedDescription)"
                    self.updateNotesTable()
                }
            }
        }
    }
    
    private func updateNotesTable() {
        // Reloads the Notes section (Index 5)
        self.tableView.reloadSections(IndexSet(integer: 5), with: .automatic)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @objc private func shareTapped() {
        shareAsPDF()
    }
    
    @IBAction func backTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "Home.")
        
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
    // MARK: - PDF Generation
    
    private func shareAsPDF() {
        var pdfContent = "Conversation Title: \(conversationTitle)\n\n"
        
        // Add AI Notes to PDF
        pdfContent += "--- AI SUMMARY ---\n"
        pdfContent += "\(notesText)\n\n"
        
        // Add Participant Data
        pdfContent += "--- PARTICIPANTS ---\n"
        for person in participantsData {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }
        
        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            
            // iPad crash fix
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
    
    // MARK: - Table View Data Source
    
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QCSummarySectionHeaderCell
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! QCSummaryCardCell
            cell.titleTextField.text = conversationTitle
            cell.delegate = self
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath) as! QCParticipantsSummaryHeaderCell
            return cell
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! QCParticipantCardCell
            let data = participantsData[indexPath.row]
            cell.configure(with: data)
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QCSummarySectionHeaderCell
            cell.headerLabel.text = "AI Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! QCNotesCardCell
            
            // --- AI DATA BINDING ---
            cell.notesTextView.text = notesText
            // Visual indicator if processing
            cell.notesTextView.textColor = isProcessing ? .secondaryLabel : .label
            // -----------------------
            
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - Delegates
    
    func didUpdateText(in cell: QCNotesCardCell) {
        // Save manual edits
        notesText = cell.notesTextView.text
        
        tableView.performBatchUpdates(nil, completion: nil)
        if let indexPath = tableView.indexPath(for: cell) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }

    func didChangeTitle(text: String) {
        conversationTitle = text
    }
}
