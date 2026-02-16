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
        
        if !transcriptMessages.isEmpty {
            prepareParticipantsFromMessages()
        }
        
        generateAISummary()
    }
    
    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        GroupNewTableView.delegate = self
        GroupNewTableView.dataSource = self
        GroupNewTableView.separatorStyle = .none
        GroupNewTableView.rowHeight = UITableView.automaticDimension
        GroupNewTableView.estimatedRowHeight = 120
    }
    
    // MARK: - Actions (Share & Dismiss)
    
    @IBAction func didTapDone() {
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
    
    @IBAction func didTapShare(_ sender: UIBarButtonItem) {
        shareAsPDF()
    }
    
    // MARK: - PDF Generation Logic (Matches QuickCaptioning)
    private func shareAsPDF() {
        // 1. Build the text content for the PDF
        var pdfContent = "Conversation Title: \(conversationTitle)\n"
        pdfContent += "\(dateString) | \(timeString) | \(locationString)\n\n"
        
        pdfContent += "--- NOTES ---\n"
        pdfContent += "\(notesText)\n\n"
        
        pdfContent += "--- PARTICIPANTS ---\n"
        for person in participantsData {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }
        
        // 2. Generate and present
        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            
            // iPad Popover Support
            if let popover = activityVC.popoverPresentationController {
                popover.barButtonItem = GroupNewShareButton
            }
            
            self.present(activityVC, animated: true, completion: nil)
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
            // Add padding (margin)
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
    
    // MARK: - Date & Time Logic
    private func generateDateAndTime() {
        let now = Date()
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "MMMM"
        let month = dateFormatter.string(from: now)

        let calendar = Calendar.current
        let day = calendar.component(.day, from: now)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .ordinal
        let dayWithSuffix = numberFormatter.string(from: NSNumber(value: day)) ?? "\(day)"

        dateFormatter.dateFormat = "h:mm a"
        self.timeString = dateFormatter.string(from: now)

        self.dateString = "\(month) \(dayWithSuffix)"
    }
    
    // MARK: - Location Logic
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc) { placemarks, error in
            if let place = placemarks?.first {
                let city = place.locality ?? ""
                let country = place.country ?? ""
                if !city.isEmpty {
                    self.locationString = "\(city), \(country)"
                    DispatchQueue.main.async {
                        if self.GroupNewTableView.numberOfSections > 1 {
                            self.GroupNewTableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
                        }
                    }
                }
            }
        }
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Data Preparation
    private func prepareParticipantsFromMessages() {
        let uniqueSenders = Set(transcriptMessages.map { $0.sender }).sorted()
        
        participantsData = uniqueSenders.map { name in
            GroupNewParticipantData(name: name, summary: "Waiting for analysis...")
        }
        GroupNewTableView.reloadData()
    }
    
    // MARK: - AI Logic
    private func generateAISummary() {
        guard !transcriptMessages.isEmpty else {
            self.notesText = "No transcript available."
            self.GroupNewTableView.reloadData()
            return
        }
        
        isProcessing = true
        let transcriptText = transcriptMessages.map { "\($0.sender): \($0.text)" }.joined(separator: "\n")
        
        Task {
            do {
                let prompt = """
                Analyze the following transcript.
                
                Step 1: Write a section strictly labeled "NOTES:" containing bullet points of action items, key takeaways, and dates mentioned.
                
                Step 2: For each participant, write a section strictly labeled "SUMMARY_[Name]:" containing a short summary of what they said in third person.
                
                TRANSCRIPT:
                \(transcriptText)
                """
                
                let session = LanguageModelSession(model: model)
                let response = try await session.respond(to: prompt)
                
                await MainActor.run {
                    self.parseAIResponse(response.content)
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
                let start = line.index(line.startIndex, offsetBy: 8)
                if let end = line.firstIndex(of: ":") {
                    let name = String(line[start..<end])
                    currentSection = name
                    continue
                }
            }
            
            if currentSection == "NOTES" {
                notesBuffer += line + "\n"
            } else if !currentSection.isEmpty {
                let existing = participantSummaries[currentSection] ?? ""
                participantSummaries[currentSection] = existing + line + " "
            }
        }
        
        self.notesText = notesBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.notesText.isEmpty { self.notesText = text }
        
        for (name, summary) in participantSummaries {
            if let index = participantsData.firstIndex(where: { $0.name == name }) {
                participantsData[index].summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            }
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupNewSummarySectionHeaderCell
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! GroupNewSummaryCardCell
            cell.configure(
                title: self.conversationTitle,
                date: self.dateString,
                time: self.timeString,
                location: self.locationString
            )
            cell.delegate = self
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupNewSummarySectionHeaderCell
            return cell
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath) as! GroupNewParticipantsSummaryHeaderCell
            let data = participantsData[indexPath.row]
            cell.configure(with: data)
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupNewSummarySectionHeaderCell
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! GroupNewNotesCardCell
            cell.notesTextView.text = self.notesText
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func didUpdateText(in cell: GroupNewNotesCardCell) {
        notesText = cell.notesTextView.text
        GroupNewTableView.performBatchUpdates(nil)
        
        // Auto-scroll to keep editing area visible
        if let indexPath = GroupNewTableView.indexPath(for: cell) {
            GroupNewTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func didChangeTitle(text: String) {
        self.conversationTitle = text
    }
}
