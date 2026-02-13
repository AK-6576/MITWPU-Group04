import UIKit
import PDFKit

// MARK: - Summary Base Class
class BaseSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotesCardCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    /// Updated to String to support custom categories like "Orasad" or "Office"
    /// didSet ensures the Page Title updates as soon as the category is assigned
    var category: String = "Family" {
        didSet {
            self.title = "\(category) Summary"
        }
    }
    
    var conversationTitle = "Conversation Summary"
    
    // Using the unified ParticipantData struct
    var participants: [ParticipantData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial title setup
        self.title = "\(category) Summary"
        
        setupUI()
        //loadParticipants()
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
//    
//    private func loadParticipants() {
//        // Fetches the real list from the repository based on the category string
//        self.participants = ParticipantRepository.getParticipants(for: category)
//        tableView.reloadData()
//    }
//    
    @objc func dismissKeyboard() { view.endEditing(true) }
    @objc func shareTapped() { shareAsPDF() }
    
    @IBAction func backTapped(_ sender: Any) {
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! SummaryCardCell
            cell.titleLabel.text = conversationTitle
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath) as! ParticipantsSummaryHeaderCell
            cell.participantLabel.text = "Participants"
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! ParticipantCardCell
            cell.configure(with: participants[indexPath.row])
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath) as! SummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! NotesCardCell
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
