//
//  FamilySummaryViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 25/11/25.
//

import UIKit
import PDFKit

class FamilySummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotesCardCellDelegate1 {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    
    var conversationTitle = "Session"
    var participantsData: [FamilyParticipantData] = []
    var chatHistory: [ChatMessage1] = []
    var guestName: String = "Person 1"
    
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
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    // MARK: - Image Helper
    func getImageName(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("marie") { return "avatar_9" }
        if lower.contains("henry") { return "avatar_10" }
        if lower.contains("anna") { return "avatar_7" }
        return "person.circle.fill"
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func shareTapped() {
        shareAsPDF()
    }
    
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

    func shareAsPDF() {
        var pdfContent = "Conversation Title: \(conversationTitle)\n\n"
        pdfContent += "--- SUMMARY ---\n\n"
        for person in participantsData {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell1", for: indexPath) as! SummarySectionHeaderCell1
            cell.headerLabel.text = "Conversation Summary"
            cell.headerIcon.image = UIImage(systemName: "list.bullet.clipboard")
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell1", for: indexPath) as! SummaryCardCell1
            cell.titleLabel.text = conversationTitle
            return cell
        case 2:
            return tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell1", for: indexPath)
        case 3:

            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell1", for: indexPath) as! ParticipantCardCell1
            let data = participantsData[indexPath.row]
            
            cell.configure(with: data)
            
            let imgName = getImageName(for: data.name)
            if let image = UIImage(named: imgName) {
                cell.avatarImageView.image = image
            } else {
                cell.avatarImageView.image = UIImage(systemName: "person.circle.fill")
            }
            
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell1", for: indexPath) as! SummarySectionHeaderCell1
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell1", for: indexPath) as! NotesCardCell1
            cell.delegate = self
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func didUpdateText(in cell: NotesCardCell1) {
        tableView.performBatchUpdates(nil, completion: nil)
        if let indexPath = tableView.indexPath(for: cell) {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
}
