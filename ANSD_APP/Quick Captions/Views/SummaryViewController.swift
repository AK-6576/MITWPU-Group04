//
//  SummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import PDFKit

class SummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, QuickCaptionsNotesCardCellDelegate, QuickCaptionsSummaryCardDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var conversationTitle = "Conversation 1"
    var participantsData: [QuickCaptionsParticipants] = []
    
    // Function - Initializes the view lifecycle, setting up the table view properties, button targets, and gesture recognizers for keyboard handling.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        if let shareBtn = shareButton {
            shareBtn.target = self
            shareBtn.action = #selector(shareTapped)
        } else {
            print("WARNING: optionsButton is nil. Check Storyboard connection.")
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    // Function - Dismisses the keyboard by resigning the first responder status on the view.
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    
    // Function - Triggered when the share button is tapped, initiating the PDF generation and sharing process.
    @objc private func shareTapped() {
        shareAsPDF()
    }
    
    // Function - Navigates back to the Home screen by resetting the window's root view controller with a transition animation.
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
    
    // Function - Compiles the conversation data into a string, generates a PDF, and presents the share sheet.
    private func shareAsPDF() {
        var pdfContent = "Conversation Title: \(conversationTitle)\n\n"
        for person in participantsData {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }
        
        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
    }
    
    // Function - Renders the provided text string into a PDF file saved in the temporary directory and returns its URL.
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
    
    // Function - Returns the total number of sections in the table view structure (Headers, Cards, etc.).
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }

    // Function - Returns the number of rows for a specific section, allowing for multiple participant rows in section 3.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 { return participantsData.count }
        return 1
    }
    
    // Function - Dequeues and configures the appropriate cell type based on the section index (Headers, Summaries, Participants, Notes).
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QuickCaptionsSummarySectionHeaderCell
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! QuickCaptionsSummaryCardCell
            cell.titleTextField.text = conversationTitle
            cell.delegate = self
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath) as! QuickCaptionsParticipantsSummaryHeaderCell
            return cell
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! QuickCaptionsParticipantCardCell
            let data = participantsData[indexPath.row]
            cell.configure(with: data)
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QuickCaptionsSummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! QuickCaptionsNotesCardCell
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - Delegates
    
    // Function - Updates the table view layout dynamically when text is entered into the notes cell.
    func didUpdateText(in cell: QuickCaptionsNotesCardCell) {
        tableView.performBatchUpdates(nil, completion: nil)
        if let indexPath = tableView.indexPath(for: cell) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }

    // Function - Updates the local conversation title variable whenever the user edits the title text field.
    func didChangeTitle(text: String) {
        conversationTitle = text
    }
}
