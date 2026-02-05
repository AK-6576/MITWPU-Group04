import UIKit
import PDFKit

// MARK: - Summary Base Class
class BaseSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotesCardCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    
    // MARK: - Properties
    // This matches the enum in FamilyChat.swift
    var category: ChatCategory = .family
    var conversationTitle = "Conversation Summary"
    
    // Using the unified ParticipantData struct from FamilyParticipantData.swift
    var participants: [ParticipantData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadParticipants()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        // Setup TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        // Options for PDF sharing
        optionsButton?.target = self
        optionsButton?.action = #selector(shareTapped)
        
        // Dismiss keyboard when tapping outside
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func loadParticipants() {
        // CLEAN IMPLEMENTATION: Fetches the real list from the repository
        self.participants = ParticipantRepository.getParticipants(for: category)
        tableView.reloadData()
    }
    
    @objc func dismissKeyboard() { view.endEditing(true) }
    @objc func shareTapped() { shareAsPDF() }
    
    @IBAction func backTapped(_ sender: Any) {
        if let nav = navigationController {
            nav.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    // MARK: - PDF Generation
    func shareAsPDF() {
        var pdfContent = "EchoWave Summary\n"
        pdfContent += "Category: \(category)\n"
        pdfContent += "---------------------------\n\n"
        
        for person in participants {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }

        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            present(activityVC, animated: true)
        }
    }
    
    private func createPDF(from text: String) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8))
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
            text.draw(in: CGRect(x: 40, y: 40, width: 515.2, height: 761.8), withAttributes: attributes)
        }
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("Summary.pdf")
        try? data.write(to: fileURL)
        return fileURL
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
            cell.headerLabel.text = "Analysis"
            cell.headerIcon.image = UIImage(systemName: "sparkles")
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCardCell", for: indexPath) as! SummaryCardCell
            cell.titleLabel.text = conversationTitle
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsHeaderCell", for: indexPath) as! ParticipantsSummaryHeaderCell
            cell.participantLabel.text = "Participants"
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as! ParticipantCardCell
            cell.configure(with: participants[indexPath.row])
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! SummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath) as! NotesCardCell
            cell.delegate = self
            return cell
        default: return UITableViewCell()
        }
    }
    
    func didUpdateText(in cell: NotesCardCell) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

// MARK: - Storyboard Aliases
typealias FamilySummaryViewController = BaseSummaryViewController
typealias FriendsSummaryViewController = BaseSummaryViewController
typealias OfficeSummaryViewController = BaseSummaryViewController
