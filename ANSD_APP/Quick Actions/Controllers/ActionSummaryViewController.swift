//
//  ActionSummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import PDFKit
import FoundationModels
import CoreLocation
import MapKit

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
class BaseSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotesCardCellDelegate, SummaryCardDelegate, CLLocationManagerDelegate {
    
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
    var dateString: String = ""
    var timeString: String = ""
    var locationString: String = "Location Unknown"
    
    // MARK: - AI & State Properties
    var transcriptMessages: [ChatMessage] = []
    private let model = SystemLanguageModel.default
    private var isProcessing = false
    private(set) var notesText: String = "Generating summary..."
    let locationManager = CLLocationManager()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "\(category) Summary"
        configureUI()
        generateDateAndTime()
        setupLocation()
        
        if !transcriptMessages.isEmpty {
            prepareParticipantsFromMessages()
        }
        
        generateAISummary()
    }
    
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() { view.endEditing(true) }
    @objc func shareTapped() { shareAsPDF() }
    
    @IBAction func backTapped(_ sender: Any) {
        self.view.endEditing(true)
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
        
        self.participants = ordering.map { name in
            ParticipantData(name: name, summary: "Waiting for analysis...")
        }
        tableView.reloadData()
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
        
        if let request = MKReverseGeocodingRequest(location: location) {
            request.getMapItems { mapItems, error in
                if let place = mapItems?.first?.placemark {
                    self.locationString = [place.locality, place.administrativeArea].compactMap { $0 }.joined(separator: ", ")
                    self.locationManager.stopUpdatingLocation()
                    DispatchQueue.main.async {
                        self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
                    }
                }
            }
        }
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
                let prompt = """
                Analyze the following transcript. Summarize the key takeaways and action items in short, clean sentences. DO NOT use symbols like '-', '*', or '#' for listing things. Provide each point as a standalone sentence. 
                
                The JSON must perfectly match this structure:
                {
                  "notes": "The bulleted-style string of clean standalone sentences.",
                  "participants": [
                    { "name": "Participant Name", "summary": "A short 1-2 sentence third-person summary of what they said." }
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
        
        do {
            let decodedSummary = try JSONDecoder().decode(AISummaryResponse.self, from: jsonData)
            
            self.notesText = decodedSummary.notes
            
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
            for p in participants {
                text += "\(p.name):\n\(p.summary)\n\n"
            }
            
            text.draw(in: CGRect(x: 40, y: 80, width: 515, height: 740), withAttributes: bodyAttr)
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Session Summary.pdf")
        try? data.write(to: url)
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(vc, animated: true)
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
            cell.headerLabel.text = "Conversation Summary"
            cell.headerIcon.image = UIImage(systemName: "list.clipboard")
            cell.selectionStyle = .none
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! SummaryCardCell
            cell.configure(title: conversationTitle, date: dateString, time: timeString, location: locationString)
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! SummarySectionHeaderCell
            cell.headerLabel.text = "Participant Summary"
            cell.headerIcon.image = UIImage(systemName: "person.2.fill")
            cell.selectionStyle = .none
            return cell
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! ParticipantCardCell
            cell.configure(with: participants[indexPath.row])
            cell.selectionStyle = .none
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! SummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            cell.selectionStyle = .none
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! NotesCardCell
            cell.notesTextView.text = self.notesText
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
            
        default: return UITableViewCell()
        }
    }
    
    // MARK: - Delegates
    func didUpdateText(in cell: NotesCardCell) {
        notesText = cell.notesTextView.text
        tableView.performBatchUpdates(nil)
        if let indexPath = tableView.indexPath(for: cell) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func didChangeTitle(text: String) {
        self.conversationTitle = text
    }
    
    // MARK: - Save to History
    private func saveSessionToHistory() {
        // SAFETY: If time or date is empty, generate it now
        if dateString.isEmpty || timeString.isEmpty {
            generateDateAndTime()
        }
        
        let historyParticipants: [Participant] = participants.map { person in
            Participant(name: person.name, summary: person.summary, image: "person.circle.fill")
        }
        
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
        
        let finalNotes = self.notesText == "Generating summary..." ? "No notes generated." : self.notesText
        let cleanOneLiner = finalNotes.replacingOccurrences(of: "\n", with: " ")
        
        let now = Date()
        let endTimeFormatter = DateFormatter()
        endTimeFormatter.timeStyle = .short
        let endTimeString = endTimeFormatter.string(from: now)

        let newConversation = Conversation(
            id: UUID().uuidString,
            title: self.conversationTitle,
            details: cleanOneLiner,
            date: self.dateString,
            startTime: self.timeString,
            endTime: endTimeString,
            location: self.locationString,
            category: self.category,
            icon: "bolt.fill",
            info: nil,
            calendarDate: now,
            notes: finalNotes,
            isPinned: false,
            participants: historyParticipants,
            messages: historyMessages
        )
        
        // 5. Send to DataManager to permanently save!
        DataManager.shared.addConversation(newConversation)
        
        // 6. Sync full transcript to Firebase for persistent history
        FirebaseManager.shared.saveFullConversation(newConversation)
        
        print("Success: Saved Action session \(self.conversationTitle) to History!")
    }
}

// MARK: - Storyboard Aliases
typealias ActionSummaryViewController = BaseSummaryViewController
typealias FriendsSummaryViewController = BaseSummaryViewController
typealias OfficeSummaryViewController = BaseSummaryViewController
