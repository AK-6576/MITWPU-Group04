//  GNSummaryViewController.swift
//  ANSD_APP

import UIKit
import Foundation
import FoundationModels

final class GroupNewSummaryViewController: UIViewController,
                                     UITableViewDelegate,
                                     UITableViewDataSource,
                                     GroupNewNotesCardCellDelegate,
                                     GroupNewSummaryCardDelegate {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var optionsButton: UIBarButtonItem!

    var conversationTitle: String = "New Conversation"
    
    // NEW: This will hold the real chat messages passed from the previous screen
    var transcriptMessages: [GroupNewChatMessage] = []
    
    // This is for the UI list of people
    var participantsData: [GroupNewParticipantData] = []
    
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
            GroupNewParticipantData(
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
    
    @IBAction func backTapped(_ sender: Any) {
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
    
    // MARK: - AI Summarization Logic
        private func generateAISummary() {
            // 1. Prepare raw transcript from REAL MESSAGES
            let rawTranscript = transcriptMessages.isEmpty ?
                    "No conversation data." :
                    transcriptMessages.map { "\($0.sender): \($0.text)" }.joined(separator: "\n")

                guard !transcriptMessages.isEmpty else {
                    updateNotes("No data to summarize.")
                    return
                }

                updateNotes("Apple Intelligence is analyzing your conversation...")
                isProcessing = true
            
            // 3. Apple Intelligence Task
            Task {
                do {
                    // Using the iOS 18+ LanguageModel API
                    // Note: Ensure your project has the 'Apple Intelligence' capability enabled in Entitlements
                    
                    let instructions = """
                    You are an ANSD (Auditory Neuropathy Spectrum Disorder) assistant. 
                    Summarize this transcript for a patient who has hearing difficulties.
                    Focus on:
                    1. What was decided?
                    2. What are the next steps?
                    3. List any specific names or numbers mentioned.

                    Transcript:
                    \(rawTranscript)
                    """
                    
                    let session = LanguageModelSession(instructions: instructions)
                    
                    // The prompt is just the transcript since the role is in instructions
                                let prompt = "Please summarize this transcript:\n\(rawTranscript)"
                    
                    // Generate the response
                    let response = try await session.respond(to: prompt)
                                
                                await MainActor.run {
                                    self.isProcessing = false
                                    // 'response' is a LanguageModelSession.Response<String>
                                    // We access the content (which is the summary text)
                                    self.updateNotes(response.content)
                                }
                    
                } catch {
                        print("Apple Intelligence Error: \(error)")
                        await MainActor.run {
                            self.isProcessing = false
                            self.updateNotes("Summary unavailable. Raw transcript:\n\n" + rawTranscript)
                        }
                    }
            }
        }

        private func updateNotes(_ text: String) {
            notesText = text
            // Section 5 is where your NotesCardCell lives
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.reloadSections(IndexSet(integer: 5), with: .fade)
                self.tableView.endUpdates()
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
            ) as! GroupNewNotesCardCell

            cell.notesTextView.text = notesText
            cell.notesTextView.textColor = isProcessing ? .secondaryLabel : .label
            cell.delegate = self
            return cell
        }

        return UITableViewCell()
    }

    // MARK: - Delegates
    func didUpdateText(in cell: GroupNewNotesCardCell) {
        notesText = cell.notesTextView.text
    }

    func didChangeTitle(text: String) {
        conversationTitle = text
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task {
            // Check if we have a session
            let authenticated = await SupabaseManager.shared.isUserAuthenticated()
            
            if !authenticated {
                do {
                    print("No session found. Attempting anonymous sign-in...")
                    try await SupabaseManager.shared.signInAnonymously()
                    print("Successfully signed in anonymously!")
                } catch {
                    print("Auth failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

