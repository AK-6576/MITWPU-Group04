//
//  GJSummaryViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit
import PDFKit

class GJSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GJNotesCardCellDelegate {
    
    @IBOutlet weak var GJtableView: UITableView!
    @IBOutlet weak var GJoptionsButton: UIBarButtonItem!
    
    var conversationTitle = "Session"
    var participantsData: [GJParticipantData] = []
    var chatHistory: [GJChatMessage] = []
    var guestName: String = "Person 1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        GJtableView.delegate = self
        GJtableView.dataSource = self
        GJtableView.separatorStyle = .none
        GJtableView.backgroundColor = .clear
        GJtableView.rowHeight = UITableView.automaticDimension
        GJtableView.estimatedRowHeight = 120
        
        if let shareBtn = GJoptionsButton {
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
    
    @objc func shareTapped() {
        shareAsPDF()
    }
    
    @IBAction func backTapped(_ sender: Any) {
        // 1. Get the Home Screen
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "Home.")
        
        // 2. IMPORTANT: Put Home inside a new Navigation Controller
        // This restores the "Push" ability for your other screens.
        let navController = UINavigationController(rootViewController: homeVC)
        
        // (Optional) Hide the nav bar on Home if you have a custom design like "Hello Steve"
        navController.isNavigationBarHidden = false
        navController.modalPresentationStyle = .fullScreen
        
        // 3. Swap the Root
        if let window = self.view.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = navController
            }, completion: nil)
            
            window.makeKeyAndVisible()
        }
    }
    
    func shareAsPDF() {
        var pdfContent = "Conversation Title: \(conversationTitle)\n\n"
        pdfContent += "--- SUMMARY ---\n\n"
        for person in participantsData {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }
        
        if !chatHistory.isEmpty {
            pdfContent += "--- TRANSCRIPT ---\n\n"
            for msg in chatHistory {
                pdfContent += "\(msg.sender): \(msg.text)\n"
            }
        }
        
        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
    }
    
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GJSummarySectionHeaderCell
            cell.headerLabel.text = "Conversation Summary"
            cell.headerIcon.image = UIImage(systemName: "list.bullet.clipboard")
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! GJSummaryCardCell
            cell.titleLabel.text = conversationTitle
            return cell
        case 2:
            return tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath)
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! GJParticipantCardCell
            let data = participantsData[indexPath.row]
            cell.configure(with: data)
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! GJSummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! GJNotesCardCell
            cell.delegate = self
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func didUpdateText(in cell: GJNotesCardCell) {
        GJtableView.performBatchUpdates(nil, completion: nil)
        if let indexPath = GJtableView.indexPath(for: cell) {
            GJtableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
}
