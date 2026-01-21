//  GNSummaryViewController.swift
//  ANSD_APP

import UIKit
import Foundation
import FoundationModels

final class GNSummaryViewController: UIViewController,
                                     UITableViewDelegate,
                                     UITableViewDataSource,
                                     GNNotesCardCellDelegate,
                                     GNSummaryCardDelegate {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var optionsButton: UIBarButtonItem!

    var conversationTitle: String = "New Conversation"
    
    // NEW: This will hold the real chat messages passed from the previous screen
    var transcriptMessages: [GNChatMessage] = []
    
    // This is for the UI list of people
    var participantsData: [GNParticipantData] = []
    
    private(set) var notesText: String = ""
    
    // Properties for on-device AI
    private let model = SystemLanguageModel.default
    private var isProcessing = false

    // MARK: - Lifecycle
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

    // MARK: - Data Preparation
    private func prepareParticipantsFromMessages() {
        // Find unique senders
        var uniqueSenders: [String: String] = [:] // [ID: Name]
        
        for msg in transcriptMessages {
            // Check if we already have this sender
            if uniqueSenders[msg.senderID] == nil {
                uniqueSenders[msg.senderID] = msg.sender
            }
        }
        
        // Create participant objects for the table view
        self.participantsData = uniqueSenders.map { (_, name) in
            GNParticipantData(
                name: name,
                summary: "Participant", // We don't have individual summaries yet
                //imageName: "avatar_1"   // Default avatar
            )
        }
        
        self.tableView.reloadData()
    }

    // MARK: - UI
    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120

        optionsButton?.target = self
        optionsButton?.action = #selector(shareTapped)
    }

    @objc private func shareTapped() {
        shareAsPDF()
    }

    // MARK: - AI Summarization Logic
    private func generateAISummary() {
        // 1. Prepare the raw transcript from REAL MESSAGES
        var rawTranscript = ""
        
        if !transcriptMessages.isEmpty {
            // Use real chat logs: "Name: Text"
            rawTranscript = transcriptMessages
                .map { "\($0.sender): \($0.text)" }
                .joined(separator: "\n")
        } else {
            // Fallback to dummy data if no messages passed
            rawTranscript = self.participantsData
                .map { $0.summary }
                .joined(separator: "\n")
        }

        guard !rawTranscript.isEmpty else {
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
        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(integer: 5), with: .automatic)
        }
    }

    // MARK: - Export
    private func shareAsPDF() {
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: 595, height: 842)
        )

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            notesText.draw(
                in: CGRect(x: 40, y: 40, width: 515, height: 760),
                withAttributes: attributes
            )
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Summary.pdf")

        try? data.write(to: url)

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int { 6 }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        // Only show participant rows if section 3
        section == 3 ? participantsData.count : 1
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 5 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "NotesCardCell",
                for: indexPath
            ) as! GNNotesCardCell

            cell.notesTextView.text = notesText
            cell.notesTextView.textColor = isProcessing ? .secondaryLabel : .label
            cell.delegate = self
            return cell
        }

        return UITableViewCell()
    }

    // MARK: - Delegates
    func didUpdateText(in cell: GNNotesCardCell) {
        notesText = cell.notesTextView.text
    }

    func didChangeTitle(text: String) {
        conversationTitle = text
    }
}
