import UIKit

class ChatHistoryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return transcript.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Dequeue a basic cell. Ensure the reuse identifier "ChatMessageCell" is registered in storyboard or code.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatMessageCell", for: indexPath)
        return cell
    }
    
    
    // MARK: - Outlets
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var chatContainerView: UIView!
    @IBOutlet var summaryContainerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var menuButton: UIBarButtonItem!
    
    // MARK: - Properties
    var histconversationData: Conversation?
    var isHighlightModeActive = false
    
    // Computed properties for easier access
    var transcript: [Message] { histconversationData?.messages ?? [] }
    var participants: [PCParticipantData] { histconversationData?.participants ?? [] }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateContainerViews()
    }
    
    private func setupUI() {
        navigationItem.title = histconversationData?.title ?? "Details"
        
        // TableView setup for Summary
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        
        // CollectionView setup for Chat
        collectionView.delegate = self
        collectionView.dataSource = self
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }

    // MARK: - Container Logic
    @IBAction func chatNsumSegmentedController(_ sender: UISegmentedControl) {
        view.endEditing(true)
        updateContainerViews()
    }
    
    private func updateContainerViews() {
        let isChatSelected = (segmentedControl.selectedSegmentIndex == 0)
        chatContainerView.isHidden = !isChatSelected
        summaryContainerView.isHidden = isChatSelected
        
        if !isChatSelected {
            tableView.reloadData()
        } else {
            collectionView.reloadData()
        }
    }
}

// MARK: - Summary TableView Logic
extension ChatHistoryViewController: UITableViewDataSource, UITableViewDelegate, PCNotesCardCellDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Section 3 displays the participants list from JSON
        if section == 3 { return participants.count }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // Header: Summary
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummarySectionHeaderCell", for: indexPath) as! PCSummarySectionHeaderCell
            cell.headerLabel.text = "Summary"
            return cell
            
        case 1: // Card: Title & Date
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummaryCardCell", for: indexPath) as! PCSummaryCardCell
            cell.titleTextField.text = histconversationData?.title
            return cell
            
        case 2: // Header: Participants
            return tableView.dequeueReusableCell(withIdentifier: "PCParticipantsSummaryHeaderCell", for: indexPath)
            
        case 3: // Cards: Individual Participants
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCParticipantsCardCell", for: indexPath) as! PCParticipantsCardCell
            cell.configure(with: participants[indexPath.row])
            return cell
            
        case 4: // Header: Notes
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummarySectionHeaderCell", for: indexPath) as! PCSummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            return cell
            
        case 5: // Card: Editable Notes
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCNotesCardCell", for: indexPath) as! PCNotesCardCell
            cell.notesTextView.text = histconversationData?.notes ?? ""
            cell.delegate = self
            return cell
            
        default: return UITableViewCell()
        }
    }
    
    // Update data when user types in notes box
    func didUpdateText(in cell: PCNotesCardCell) {
        histconversationData?.notes = cell.notesTextView.text
        
        // This triggers the table to grow the cell height as the user types
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
