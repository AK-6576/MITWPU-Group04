//
//  GroupJoinSummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import PDFKit
import FoundationModels // Apple Intelligence
import CoreLocation

class GroupJoinSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupJoinNotesCardCellDelegate, GroupJoinSummaryCardDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var GroupJoinTableView: UITableView!
    @IBOutlet weak var GroupJoinOptionsButton: UIBarButtonItem!
    
    var conversationTitle = "Session Summary"
    var transcriptMessages: [GroupJoinChatMessage] = []
    
    // Using correct data model
    var participantsData: [GroupJoinParticipants] = []
    
    // State
    var dateString: String = ""
    var timeString: String = ""
    var locationString: String = "Location Unknown"
    
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
        
        if !transcriptMessages.isEmpty {
            prepareParticipantsFromMessages()
        }
        
        generateAISummary()
    }
    
    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        GroupJoinTableView.delegate = self
        GroupJoinTableView.dataSource = self
        GroupJoinTableView.separatorStyle = .none
        GroupJoinTableView.backgroundColor = .clear
        GroupJoinTableView.rowHeight = UITableView.automaticDimension
        GroupJoinTableView.estimatedRowHeight = 120
    }
    
    // MARK: - Actions
    @IBAction func doneButtonTapped(_ sender: Any) {
        // Go Home
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "Home")
        let nav = UINavigationController(rootViewController: homeVC)
        nav.modalPresentationStyle = .fullScreen
        self.view.window?.rootViewController = nav
    }
    
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        shareAsPDF()
    }
    
    // MARK: - Logic
    private func prepareParticipantsFromMessages() {
        let uniqueSenders = Set(transcriptMessages.map { $0.sender }).sorted()
        participantsData = uniqueSenders.map { name in
            GroupJoinParticipants(name: name, summary: "Waiting for analysis...", avatarTitle: "")
        }
        GroupJoinTableView.reloadData()
    }
    
    private func generateAISummary() {
        guard !transcriptMessages.isEmpty else {
            notesText = "No transcript."
            GroupJoinTableView.reloadData()
            return
        }
        
        isProcessing = true
        let text = transcriptMessages.map { "\($0.sender): \($0.text)" }.joined(separator: "\n")
        
        Task {
            do {
                let prompt = """
                Analyze this transcript.
                Step 1: Write section "NOTES:" with bullet points.
                Step 2: For each participant, write "SUMMARY_[Name]:" with a short summary.
                TRANSCRIPT:
                \(text)
                """
                
                // CORRECT AI CALL
                let session = LanguageModelSession(model: model)
                let response = try await session.respond(to: prompt)
                
                await MainActor.run {
                    self.parseAIResponse(response.content)
                    self.isProcessing = false
                    self.GroupJoinTableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.notesText = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                    self.GroupJoinTableView.reloadData()
                }
            }
        }
    }
    
    private func parseAIResponse(_ text: String) {
        var notesBuffer = ""
        let components = text.components(separatedBy: CharacterSet.newlines)
        var currentSection = ""
        var participantSummaries: [String: String] = [:]
        
        for line in components {
            if line.contains("NOTES:") { currentSection = "NOTES"; continue }
            if line.contains("SUMMARY_") && line.contains(":") {
                let start = line.index(line.startIndex, offsetBy: 8)
                if let end = line.firstIndex(of: ":") {
                    let name = String(line[start..<end])
                    currentSection = name
                    continue
                }
            }
            
            if currentSection == "NOTES" { notesBuffer += line + "\n" }
            else if !currentSection.isEmpty {
                let existing = participantSummaries[currentSection] ?? ""
                participantSummaries[currentSection] = existing + line + " "
            }
        }
        
        self.notesText = notesBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.notesText.isEmpty { self.notesText = text }
        
        for (name, summary) in participantSummaries {
            if let index = participantsData.firstIndex(where: { name.contains($0.name) || $0.name.contains(name) }) {
                participantsData[index].summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
    
    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int { 6 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 3 ? participantsData.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupJoinSummarySectionHeaderCell
            cell.headerLabel.text = "Conversation Summary"
            cell.headerIcon.image = UIImage(systemName: "list.clipboard")
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! GroupJoinSummaryCardCell
            cell.configure(title: conversationTitle, date: dateString, time: timeString, location: locationString)
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupJoinSummarySectionHeaderCell
            cell.headerLabel.text = "Participants"
            cell.headerIcon.image = UIImage(systemName: "person.2.fill")
            return cell
        case 3:
            // USES THE CARD CELL (White Background)
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! GroupJoinParticipantsCardCell
            cell.configure(with: participantsData[indexPath.row])
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupJoinSummarySectionHeaderCell
            cell.headerLabel.text = "AI Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! GroupJoinNotesCardCell
            cell.notesTextView.text = notesText
            cell.delegate = self
            return cell
        default: return UITableViewCell()
        }
    }
    
    // MARK: - Helpers (Date, Location, PDF)
    private func generateDateAndTime() {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateString = dateFormatter.string(from: now)
        let timeFormatter = DateFormatter()
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
                    self.GroupJoinTableView.reloadSections(IndexSet(integer: 1), with: .none)
                }
            }
        }
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
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SessionSummary.pdf")
        try? data.write(to: url)
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = vc.popoverPresentationController {
            popover.barButtonItem = GroupJoinOptionsButton
        }
        present(vc, animated: true)
    }
    
    func didUpdateText(in cell: GroupJoinNotesCardCell) {
        notesText = cell.notesTextView.text
        GroupJoinTableView.performBatchUpdates(nil)
        if let indexPath = GroupJoinTableView.indexPath(for: cell) {
            GroupJoinTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    func didChangeTitle(text: String) { conversationTitle = text }
}
