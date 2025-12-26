//
//  SummaryViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 25/11/25.
//

import UIKit
import PDFKit

class OfficeSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotesCardCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    
    var conversationTitle = "Session"
    var participantsData: [ParticipantData] = []
    
    var chatHistory: [ChatMessage] = []
    var guestName: String = "Person 1"
    
    // MARK: - Lifecycle
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
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    
    // 1. TOP RIGHT: Direct Share
    @objc func shareTapped() {
        shareAsPDF()
    }
    
    // 2. TOP LEFT: Exit to Home Screen
    @IBAction func backTapped(_ sender: Any) {
        if let navController = self.view.window?.rootViewController as? UINavigationController {
            // Reset background stack to Home
            navController.popToRootViewController(animated: false)
            // Dismiss the Summary Modal
            navController.dismiss(animated: true, completion: nil)
        } else {
            // Fallback
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - PDF Logic
    func shareAsPDF() {
        var pdfContent = "Conversation Title: \(conversationTitle)\n\n"
        
        pdfContent += "--- SUMMARY ---\n\n"
        for person in participantsData {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }

        if let pdfURL = createPDF(from: pdfContent) {
            
            // Native Share Sheet (Slides from bottom)
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            
            self.present(activityVC, animated: true)
        }
    }
    
    // MARK: - PDF Generator Helper
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! SummarySectionHeaderCell
            cell.headerLabel.text = "Conversation Summary"
            cell.headerIcon.image = UIImage(systemName: "list.bullet.clipboard")
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! SummaryCardCell
            // FIX: Use Label or TextField depending on your cell design
            cell.titleLabel.text = conversationTitle
            return cell
            
        case 2:
            return tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath)
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! ParticipantCardCell
            let data = participantsData[indexPath.row]
            cell.configure(with: data)
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! SummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! NotesCardCell
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - Notes Delegate
    func didUpdateText(in cell: NotesCardCell) {
        tableView.performBatchUpdates(nil, completion: nil)
        if let indexPath = tableView.indexPath(for: cell) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
}
