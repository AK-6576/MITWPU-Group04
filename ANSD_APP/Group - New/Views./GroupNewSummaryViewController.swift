//
//  GroupNewSummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import PDFKit
import FoundationModels // Apple Intelligence
import CoreLocation

class GroupNewSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupNewNotesCardCellDelegate, GroupNewSummaryCardDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var GroupNewTableView: UITableView!
    @IBOutlet weak var GroupNewShareButton: UIBarButtonItem!
    
    // MARK: - Data Sources
    var conversationTitle = "Session Summary"
    var transcriptMessages: [GroupNewChatMessage] = []
    
    // This holds the Name + Summary for the list
    var participantsData: [GroupNewParticipantData] = []
    
    // MARK: - Header Data
    var dateString: String = ""
    var timeString: String = ""
    var locationString: String = "Location Unknown"
    
    // MARK: - AI & Location State
    private let model = SystemLanguageModel.default
    private var isProcessing = false
    private(set) var notesText: String = "Generating summary..."
    let locationManager = CLLocationManager()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        generateDateAndTime()
        setupLocation()
        
        // 1. Initial Data Prep (Fill list with "Waiting..." state)
        if !transcriptMessages.isEmpty {
            prepareParticipantsFromMessages()
        }
        
        // 2. Start Analysis
        generateAISummary()
    }
    
    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        
        GroupNewTableView.delegate = self
        GroupNewTableView.dataSource = self
        GroupNewTableView.separatorStyle = .none
        GroupNewTableView.backgroundColor = .clear
        
        GroupNewTableView.rowHeight = UITableView.automaticDimension
        GroupNewTableView.estimatedRowHeight = 120
        
        // Tap to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Data Preparation
    private func prepareParticipantsFromMessages() {
        // Identify all unique speakers
        var seenSenders = Set<String>()
        var ordering: [String] = []
        
        for msg in transcriptMessages {
            if !seenSenders.contains(msg.sender) {
                seenSenders.insert(msg.sender)
                ordering.append(msg.sender)
            }
        }
        
        // Initialize with "Waiting..."
        self.participantsData = ordering.map { name in
            GroupNewParticipantData(name: name, summary: "Waiting for analysis...")
        }
        
        GroupNewTableView.reloadData()
    }
    
    // MARK: - AI Summary
    private func generateAISummary() {
        guard !transcriptMessages.isEmpty else {
            self.notesText = "No conversation to summarize."
            self.GroupNewTableView.reloadData()
            return
        }
        
        isProcessing = true
        let fullTranscript = transcriptMessages.map { "\($0.sender): \($0.text)" }.joined(separator: "\n")
        
        Task {
            do {
                // Prompt: Ask for Notes AND per-person summaries
                let prompt = """
                Analyze the following transcript.
                
                Step 1: Write a section strictly labeled "NOTES:" containing bullet points of action items and key takeaways.
                
                Step 2: For each participant, write a section strictly labeled "SUMMARY_[Name]:" containing a short summary of what they said in third person.
                
                TRANSCRIPT:
                \(fullTranscript)
                """
                
                // CORRECTED: Use LanguageModelSession and respond(to:)
                let session = LanguageModelSession(model: model)
                let response = try await session.respond(to: prompt)
                
                // Parse Logic on Main Thread
                await MainActor.run {
                    self.parseAIResponse(response.content) // Use .content from the response
                    self.isProcessing = false
                    self.GroupNewTableView.reloadData()
                }
                
            } catch {
                await MainActor.run {
                    self.notesText = "Could not generate summary. Error: \(error.localizedDescription)"
                    self.isProcessing = false
                    self.GroupNewTableView.reloadData()
                }
            }
        }
    }
    
    private func parseAIResponse(_ text: String) {
        // Simple Parser to split "NOTES:" and "SUMMARY_Name:"
        var notesBuffer = ""
        let components = text.components(separatedBy: CharacterSet.newlines)
        var currentSection = ""
        
        var participantSummaries: [String: String] = [:]
        
        for line in components {
            if line.contains("NOTES:") {
                currentSection = "NOTES"
                continue
            }
            if line.contains("SUMMARY_") && line.contains(":") {
                // Extract Name
                let start = line.index(line.startIndex, offsetBy: 8) // Length of SUMMARY_
                if let end = line.firstIndex(of: ":") {
                    let name = String(line[start..<end])
                    currentSection = name
                    continue
                }
            }
            
            if currentSection == "NOTES" {
                notesBuffer += line + "\n"
            } else if !currentSection.isEmpty {
                // It's a participant summary line
                let existing = participantSummaries[currentSection] ?? ""
                participantSummaries[currentSection] = existing + line + " "
            }
        }
        
        // Update Notes
        self.notesText = notesBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.notesText.isEmpty { self.notesText = text } // Fallback
        
        // Update Participants Data
        for (name, summary) in participantSummaries {
            // Fuzzy match the name (case insensitive or contains)
            if let index = participantsData.firstIndex(where: { name.contains($0.name) || $0.name.contains(name) }) {
                participantsData[index].summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    // MARK: - Location & Date
    private func generateDateAndTime() {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateString = dateFormatter.string(from: now)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        timeString = timeFormatter.string(from: now)
    }
    
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let place = placemarks?.first {
                self.locationString = [place.locality, place.administrativeArea].compactMap { $0 }.joined(separator: ", ")
                self.locationManager.stopUpdatingLocation()
                DispatchQueue.main.async {
                    self.GroupNewTableView.reloadSections(IndexSet(integer: 1), with: .none)
                }
            }
        }
    }
    
    @IBAction func didTapDone(_ sender: Any) {
        
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
    
    // MARK: - Actions (PDF Share)
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        shareAsPDF()
    }
    
    private func shareAsPDF() {
        let pdfMetaData = [kCGPDFContextCreator: "ANSD App", kCGPDFContextTitle: conversationTitle]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8), format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let titleAttr = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
            let bodyAttr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
            
            conversationTitle.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttr)
            
            var text = "Date: \(dateString) | \(timeString)\nLocation: \(locationString)\n\n"
            text += "--- NOTES ---\n\(notesText)\n\n"
            text += "--- PARTICIPANTS ---\n"
            for p in participantsData {
                text += "\(p.name):\n\(p.summary)\n\n"
            }
            
            text.draw(in: CGRect(x: 40, y: 80, width: 515, height: 740), withAttributes: bodyAttr)
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Session Summary..pdf")
        try? data.write(to: url)
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(vc, animated: true)
    }

    // MARK: - TableView Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 {
            return participantsData.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupNewSummarySectionHeaderCell
            cell.headerLabel.text = "Conversation Summary"
            cell.headerIcon.image = UIImage(systemName: "list.clipboard")
            cell.selectionStyle = .none
            return cell
            
        case 1: // Main Card
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! GroupNewSummaryCardCell
            cell.configure(title: conversationTitle, date: dateString, time: timeString, location: locationString)
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
            
        case 2: // Header Participants
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupNewSummarySectionHeaderCell
            cell.headerLabel.text = "Participant Summary"
            cell.headerIcon.image = UIImage(systemName: "person.2.fill")
            cell.selectionStyle = .none
            return cell
            
        case 3: // LIST OF PARTICIPANTS (Using Card Cell)
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! GroupNewParticipantsCardCell
            let data = participantsData[indexPath.row]
            cell.configure(with: data)
            cell.selectionStyle = .none
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupNewSummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            cell.selectionStyle = .none
            return cell
            
        case 5: // Notes Card
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! GroupNewNotesCardCell
            cell.notesTextView.text = self.notesText
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func didUpdateText(in cell: GroupNewNotesCardCell) {
        notesText = cell.notesTextView.text
        GroupNewTableView.performBatchUpdates(nil)
        if let indexPath = GroupNewTableView.indexPath(for: cell) {
            GroupNewTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func didChangeTitle(text: String) {
        self.conversationTitle = text
    }
    
    // MARK: - Save to History
    private func saveSessionToHistory() {
        // 1. Map Participants to History Format
        let historyParticipants: [Participant] = participantsData.map { person in
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
        let newConversation = Conversation(
            id: UUID().uuidString,
            title: self.conversationTitle,
            messages: historyMessages,
            participants: historyParticipants,
            notes: finalNotes,
            description: cleanOneLiner,
            date: self.dateString,
            startTime: self.timeString,
            endTime: self.timeString,
            category: "Group-New",
            icon: "square.and.pencil"
        )
        
        // 5. Send to DataManager to permanently save!
        DataManager.shared.addConversation(newConversation)
        print("✅ Success: Saved Group New session '\(self.conversationTitle)' to History!")
    }
}
