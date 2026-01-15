//
//  ChatHistory2ViewController.swift
//  ANSD_APP
//
//  Created by SDC-USER on 06/01/26.
//

import UIKit
import PDFKit

// MARK: - Extensions

extension Notification.Name {
    static let conversationUpdated = Notification.Name("ConversationUpdated")
}

// MARK: - Protocols

// Delegate for handling text updates in notes card cells
protocol PCNotesCardCellDelegate: AnyObject {
    func didUpdateText(in cell: PCNotesCardCell)
}

// Delegate for handling title changes in summary cards
protocol PCSummaryCardDelegate: AnyObject {
    func didChangeTitle(text: String)
}

// MARK: - Custom TableView Cell Classes

// Header cell for summary section with icon and label
class PCSummarySectionHeaderCell: UITableViewCell {
    @IBOutlet weak var headerIcon: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 20
    }
}

// Header cell for participants section
class PCParticipantsSummaryHeaderCell: UITableViewCell {
    @IBOutlet weak var participantIcon: UIImageView!
    @IBOutlet weak var participantLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 20
    }
}

// Header cell for notes section
class PCNotesSectionHeaderCell: UITableViewCell {
    @IBOutlet weak var notesIcon: UIImageView!
    @IBOutlet weak var notesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
    }
}

// Card cell displaying conversation summary with editable title
class PCSummaryCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    weak var delegate: PCSummaryCardDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        mainCardView.backgroundColor = .white
        mainCardView.layer.cornerRadius = 20
        contentView.layer.cornerRadius = 20
    }
    
    // Notifies delegate when the conversation title is edited
    @IBAction func titleChanged(_ sender: UITextField) {
        delegate?.didChangeTitle(text: sender.text ?? "")
    }
}

// Card cell displaying individual participant information
class PCParticipantsCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        avatarImageView.layer.cornerRadius = 4
        avatarImageView.clipsToBounds = true
        avatarImageView.tintColor = .systemGray
        mainCardView.layer.cornerRadius = 16
        mainCardView.backgroundColor = .white
    }
    
    // Populates the cell with participant data
    func configure(with data: PCParticipantData) {
        detailsLabel.text = data.summary
    }
}

// Card cell with expandable text view for conversation notes
class PCNotesCardCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var notesTextView: UITextView!
    
    weak var delegate: PCNotesCardCellDelegate?
    let placeholderText = "Add notes about this conversation..."
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        notesTextView.delegate = self
        notesTextView.text = placeholderText
        notesTextView.textColor = .lightGray
        notesTextView.font = UIFont.systemFont(ofSize: 15)
        notesTextView.isScrollEnabled = false
        notesTextView.textContainerInset = .zero
        notesTextView.textContainer.lineFragmentPadding = 0
        mainCardView.backgroundColor = .white
        mainCardView.layer.cornerRadius = 20
    }
    
    // Removes placeholder text when user begins editing
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = nil
            textView.textColor = UIColor.label
        }
    }
    
    // Restores placeholder if text view is empty after editing
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholderText
            textView.textColor = .lightGray
        }
    }
    
    // Notifies delegate of text changes for dynamic height adjustment
    func textViewDidChange(_ textView: UITextView) {
        delegate?.didUpdateText(in: self)
    }
}

// MARK: - Main View Controller

// Manages conversation details with segmented control for chat and summary views
class ChatHistory2ViewController: UIViewController {
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var chatContainerView: UIView!
    @IBOutlet var summaryContainerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    let emptyChatLabel = UILabel()
    var histconversationData: Conversation?
    var isHighlightModeActive = false
    var conversationTitle = "Conversation Summary"
    var participantsData: [PCParticipantData] = []
    
    var transcript: [Message] {
        return histconversationData?.messages ?? []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        if let participants = histconversationData?.participants {
            self.participantsData = participants
        }
        
        setupNavigation()
        setupChatUI()
        setupSummaryUI()
        setupShareButton()
        updateContainerViews()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    // Dismisses the keyboard when tapping outside text fields
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Setup Methods
    
    // Configures navigation bar title from conversation data
    private func setupNavigation() {
        if let convoData = histconversationData {
            navigationItem.title = convoData.title
            conversationTitle = convoData.title
        } else {
            navigationItem.title = "Details"
        }
    }
    
    // Sets up chat collection view with auto-sizing cells
    private func setupChatUI() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.layer.cornerRadius = 20
        chatContainerView.layer.cornerRadius = 20
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        
        setupEmptyChatLabel()
        collectionView.reloadData()
        
        if !transcript.isEmpty {
            DispatchQueue.main.async {
                self.scrollToBottom(animated: false)
            }
        }
    }
    
    // Configures summary table view with dynamic row heights
    private func setupSummaryUI() {
        view.backgroundColor = .systemGroupedBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.layer.cornerRadius = 20
        summaryContainerView.layer.cornerRadius = 20
    }
    
    // MARK: - Share Button Logic
    
    // Configures the menu button as a share button with direct action
    private func setupShareButton() {
        if let shareBtn = menuButton {
            shareBtn.menu = nil
            shareBtn.primaryAction = UIAction { [weak self] _ in
                self?.shareAsPDF()
            }
        }
    }
    
    // Posts notification when conversation data changes to update other views
    private func notifyDataChanged() {
        if let updatedConvo = self.histconversationData {
            NotificationCenter.default.post(
                name: .conversationUpdated,
                object: nil,
                userInfo: ["updatedConversation": updatedConvo]
            )
        }
    }

    // MARK: - Actions
    
    // Switches between chat and summary views based on segmented control
    @IBAction func chatNsumSegmentedController(_ sender: UISegmentedControl) {
        view.endEditing(true)
        updateContainerViews()
    }
    
    // Shows or hides chat and summary containers based on selection
    private func updateContainerViews() {
        let isChatSelected = (segmentedControl.selectedSegmentIndex == 0)
        chatContainerView.isHidden = !isChatSelected
        summaryContainerView.isHidden = isChatSelected
        
        if isChatSelected {
            updateEmptyState()
        } else {
            tableView.reloadData()
        }
    }
    
    // Toggles visibility of collection view and empty state label
    private func updateEmptyState() {
        let isEmpty = transcript.isEmpty
        collectionView.isHidden = isEmpty
        emptyChatLabel.isHidden = !isEmpty
    }
    
    // Scrolls collection view to show the most recent message
    private func scrollToBottom(animated: Bool = true) {
        guard !transcript.isEmpty else { return }
        let lastItem = transcript.count - 1
        collectionView.scrollToItem(at: IndexPath(item: lastItem, section: 0), at: .bottom, animated: animated)
    }

    // Creates and positions the empty state label for when no messages exist
    private func setupEmptyChatLabel() {
        emptyChatLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyChatLabel.text = "No chat transcript available."
        emptyChatLabel.textColor = .systemGray
        emptyChatLabel.textAlignment = .center
        chatContainerView.addSubview(emptyChatLabel)
        NSLayoutConstraint.activate([
            emptyChatLabel.centerXAnchor.constraint(equalTo: chatContainerView.centerXAnchor),
            emptyChatLabel.centerYAnchor.constraint(equalTo: chatContainerView.centerYAnchor)
        ])
    }
    
    // Presents an alert dialog allowing the user to edit a message
    private func showEditAlert(for indexPath: IndexPath) {
        let message = transcript[indexPath.row]
        let alert = UIAlertController(title: "Edit Message", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = message.text }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let newText = alert.textFields?.first?.text {
                self.histconversationData?.messages?[indexPath.row].text = newText
                self.collectionView.reloadItems(at: [indexPath])
                self.notifyDataChanged()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - PDF Generation

extension ChatHistory2ViewController {
    
    // Generates a PDF from conversation data and presents share sheet
    private func shareAsPDF() {
        var pdfContent = "Conversation Title: \(conversationTitle)\n\n"
        
        for person in participantsData {
            pdfContent += "\(person.name):\n\(person.summary)\n\n"
        }
        
        if let notes = histconversationData?.notes, !notes.isEmpty {
            pdfContent += "Notes:\n\(notes)\n\n"
        }
        
        if let pdfURL = createPDF(from: pdfContent) {
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
    }
    
    // Creates a PDF file from text content and returns the temporary file URL
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
        let safeTitle = conversationTitle.replacingOccurrences(of: "/", with: "-")
        let fileName = "\(safeTitle) - Summary.pdf"
        let fileURL = tempFolder.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error generating PDF: \(error)")
            return nil
        }
    }
}

// MARK: - Collection View Delegate & Data Source

extension ChatHistory2ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Returns the number of messages to display in the chat
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return transcript.count
    }
    
    // Configures and returns chat message cells with highlighting support
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = transcript[indexPath.row]
        
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PCIncomingCell", for: indexPath) as! PC2IncomingViewCell
            if message.isHighlighted {
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: UIColor.black
                ]
                cell.messageLabel.attributedText = NSAttributedString(string: message.text, attributes: textAttributes)
            } else {
                cell.messageLabel.attributedText = nil
                cell.messageLabel.text = message.text
            }
            cell.nameLabel.text = message.senderName
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PCOutCell", for: indexPath) as! PCOutgoing2Cell
            if message.isHighlighted {
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: UIColor.white
                ]
                cell.PCmessageLabel.attributedText = NSAttributedString(string: message.text, attributes: textAttributes)
            } else {
                cell.PCmessageLabel.attributedText = nil
                cell.PCmessageLabel.text = message.text
            }
            return cell
        }
    }
    
    // Returns fixed size for message cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 100)
    }

    // Provides context menu for highlighting and editing messages
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let highlight = UIAction(title: "Highlight", image: UIImage(systemName: "highlighter")) { _ in
                let currentStatus = self.histconversationData?.messages?[indexPath.row].isHighlighted ?? false
                self.histconversationData?.messages?[indexPath.row].isHighlighted = !currentStatus
                collectionView.reloadItems(at: [indexPath])
                self.notifyDataChanged()
            }
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
                self.showEditAlert(for: indexPath)
            }
            return UIMenu(title: "", children: [highlight, edit])
        }
    }
}

// MARK: - Table View Delegate & Data Source

extension ChatHistory2ViewController: UITableViewDelegate, UITableViewDataSource, PCSummaryCardDelegate, PCNotesCardCellDelegate {
    
    // Saves notes text and adjusts table view height dynamically
    func didUpdateText(in cell: PCNotesCardCell) {
        if cell.notesTextView.text != cell.placeholderText {
            self.histconversationData?.notes = cell.notesTextView.text
            
            // Modern alternative to beginUpdates/endUpdates
            tableView.performBatchUpdates(nil, completion: nil)
            
            self.notifyDataChanged()
        }
    }
    
    // Updates conversation title across all views when edited
    func didChangeTitle(text: String) {
        self.conversationTitle = text
        self.histconversationData?.title = text
        self.navigationItem.title = text
        self.notifyDataChanged()
    }
        
    // Returns the number of sections in the summary table
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
        
    // Returns row count for each section, with participants section having variable rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 { return participantsData.count }
        return 1
    }
        
    // Configures and returns cells for each section of the summary view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummarySectionHeaderCell", for: indexPath) as! PCSummarySectionHeaderCell
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummaryCardCell", for: indexPath) as! PCSummaryCardCell
            cell.titleTextField.text = conversationTitle
            cell.delegate = self
            return cell
            
        case 2:
            return tableView.dequeueReusableCell(withIdentifier: "PCParticipantsSummaryHeaderCell", for: indexPath) as! PCParticipantsSummaryHeaderCell
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCParticipantsCardCell", for: indexPath) as! PCParticipantsCardCell
            cell.configure(with: participantsData[indexPath.row])
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummarySectionHeaderCell", for: indexPath) as! PCSummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCNotesCardCell", for: indexPath) as! PCNotesCardCell
            let savedNotes = histconversationData?.notes ?? ""
            if !savedNotes.isEmpty {
                cell.notesTextView.text = savedNotes
                cell.notesTextView.textColor = .label
            }
            cell.delegate = self
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}
