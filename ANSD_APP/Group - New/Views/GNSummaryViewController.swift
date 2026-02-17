//
//  GNSummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import PDFKit

class GNSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupNewNotesCardCellDelegate, GroupNewSummaryCardDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    
    var conversationTitle = "New Conversation"
    var participantsData: [GroupNewParticipants] = []
    
    // Function - Initializes the view lifecycle, setting up the table view properties, options button target, and keyboard dismissal gesture.
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
    }
    
    // Function - Resigns the first responder status to dismiss the keyboard when the user taps outside.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Function - Action triggered by the options button to initiate the PDF sharing process.
    @objc func shareTapped() {
        shareAsPDF()
    }
    
    // Function - Navigates back to the Home screen using a cross-dissolve transition on the window's root view controller.
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
    
    // Function - Compiles the conversation details into a string, generates a PDF, and presents the share sheet.
    func shareAsPDF() {
        var pdfContent = "Conversation Title: \(conversationTitle)\n\n"
        for person in participantsData {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }
        
        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
    }
    
    // Function - Renders the provided text content into a PDF file in the temporary directory and returns its URL.
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
    
    // Function - Returns the total number of sections in the table view (Headers, Summary, Participants, Notes).
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    // Function - Returns the number of rows for each section, handling the dynamic count for the participants section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 { return participantsData.count }
        return 1
    }
    
    // Function - Dequeues and configures the specific cell type required for each section (Header, Summary Card, Participant Card, Notes Card).
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupNewSummarySectionHeaderCell
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! GroupNewSummaryCardCell
            cell.titleTextField.text = conversationTitle
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath) as! GroupNewParticipantsSummaryHeaderCell
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! GroupNewParticipantCardCell
            let data = participantsData[indexPath.row]
            cell.configure(with: data)
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GroupNewSummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! GroupNewNotesCardCell
            cell.delegate = self
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    // Function - Updates the table view layout dynamically as the user types in the notes cell to adjust height.
    func didUpdateText(in cell: GroupNewNotesCardCell) {
        tableView.performBatchUpdates(nil, completion: nil)
        if let indexPath = tableView.indexPath(for: cell) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    // Function - Updates the local conversation title variable when the user edits the title text field.
    func didChangeTitle(text: String) {
        conversationTitle = text
    }
}
