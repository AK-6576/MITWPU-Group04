//
//  ChatHistoryViewController.swift
//  ANSD_APP
//
//  Created by SDC-USER on 06/01/26.
//

import UIKit
import PDFKit

// MARK: - Protocols

protocol ViewNotesCardCellDelegate: AnyObject {
    func didUpdateText(in cell: ViewNotesCardCell)
}

protocol ViewSummaryCardDelegate: AnyObject {
    func didChangeTitle(text: String)
}

// MARK: - Custom TableView Cell Classes

class ViewSummarySectionHeaderCell: UITableViewCell {
    @IBOutlet weak var headerIcon: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    // Function - Prepares the receiver for service after it has been loaded from an Interface Builder archive.
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 20
    }
}

class ViewParticipantsSummaryHeaderCell: UITableViewCell {
    @IBOutlet weak var participantIcon: UIImageView!
    @IBOutlet weak var participantLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 20
    }
}

class ViewNotesSectionHeaderCell: UITableViewCell {
    @IBOutlet weak var notesIcon: UIImageView!
    @IBOutlet weak var notesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
    }
}

class ViewSummaryCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    weak var delegate: ViewSummaryCardDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        mainCardView.backgroundColor = .white
        mainCardView.layer.cornerRadius = 20
        contentView.layer.cornerRadius = 20
    }
    
    @IBAction func titleChanged(_ sender: UITextField) {
        delegate?.didChangeTitle(text: sender.text ?? "")
    }
}

class ViewParticipantsCardCell: UITableViewCell {
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
    
    func configure(with data: Participants) {
        detailsLabel.text = data.summary
    }
}

class ViewNotesCardCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var notesTextView: UITextView!
    
    weak var delegate: ViewNotesCardCellDelegate?
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = nil
            textView.textColor = UIColor.label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholderText
            textView.textColor = .lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        delegate?.didUpdateText(in: self)
    }
}

// MARK: - Main View Controller

class ChatHistoryViewController: UIViewController {
    
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
    var participantsData: [Participants] = []
    
    var transcript: [Message] {
        return histconversationData?.messages ?? []
    }

    // Function - Initializes the view lifecycle, setting up the table view properties and gesture recognizers.
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
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Setup Methods

    private func setupNavigation() {
        if let convoData = histconversationData {
            navigationItem.title = convoData.title
            conversationTitle = convoData.title
        } else {
            navigationItem.title = "Details"
        }
    }
    
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
    
    private func setupShareButton() {
        if let shareBtn = menuButton {
    
            shareBtn.target = self
            shareBtn.action = #selector(shareTapped)
        }
    }
    
    @objc private func shareTapped() {
        shareAsPDF()
    }
    

    private func notifyDataChanged() {
        if let updatedConvo = self.histconversationData {
            NotificationCenter.default.post(
                name: NSNotification.Name("ConversationUpdated"),
                object: nil,
                userInfo: ["updatedConversation": updatedConvo]
            )
        }
    }

    // MARK: - Actions
    
    @IBAction func chatNsumSegmentedController(_ sender: UISegmentedControl) {
        view.endEditing(true)
        updateContainerViews()
    }
    
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

    private func updateEmptyState() {
        let isEmpty = transcript.isEmpty
        collectionView.isHidden = isEmpty
        emptyChatLabel.isHidden = !isEmpty
    }

    private func scrollToBottom(animated: Bool = true) {
        guard !transcript.isEmpty else { return }
        let lastItem = transcript.count - 1
        collectionView.scrollToItem(at: IndexPath(item: lastItem, section: 0), at: .bottom, animated: animated)
    }

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
    
    private func showEditAlert(for indexPath: IndexPath) {
        let message = transcript[indexPath.row]
        let alert = UIAlertController(title: "Edit Message", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = message.text }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let newText = alert.textFields?.first?.text {
                // 1. Update the text
                self.histconversationData?.messages?[indexPath.row].text = newText
                
                // 2. Set the edited flag to true
                self.histconversationData?.messages?[indexPath.row].isEdited = true
                
                // 3. Refresh the UI
                self.collectionView.reloadItems(at: [indexPath])
                self.notifyDataChanged()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - PDF Generation

extension ChatHistoryViewController {

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

extension ChatHistoryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return transcript.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = transcript[indexPath.row]
        
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PCIncomingCell", for: indexPath) as! ViewIncomingCell
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
            cell.editedLabel.isHidden = !message.isEdited
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PCOutCell", for: indexPath) as! ViewOutgoingCell
            if message.isHighlighted {
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: UIColor.white
                ]
                cell.PCmessageLabel.attributedText = NSAttributedString(string: message.text, attributes: textAttributes)
            } else {
                cell.PCmessageLabel.attributedText = nil
                cell.PCmessageLabel.text = message.text
                cell.editedLabel.isHidden = !message.isEdited
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 100)
    }

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

extension ChatHistoryViewController: UITableViewDelegate, UITableViewDataSource, ViewSummaryCardDelegate, ViewNotesCardCellDelegate {
    
    func didUpdateText(in cell: ViewNotesCardCell) {
        if cell.notesTextView.text != cell.placeholderText {
            self.histconversationData?.notes = cell.notesTextView.text
            
            tableView.beginUpdates()
            tableView.endUpdates()
            
            self.notifyDataChanged()
        }
    }
    
    func didChangeTitle(text: String) {
        self.conversationTitle = text
        self.histconversationData?.title = text
        self.navigationItem.title = text
        self.notifyDataChanged()
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummarySectionHeaderCell", for: indexPath) as! ViewSummarySectionHeaderCell
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummaryCardCell", for: indexPath) as! ViewSummaryCardCell
            cell.titleTextField.text = conversationTitle
            cell.delegate = self
            return cell
            
        case 2:
            return tableView.dequeueReusableCell(withIdentifier: "PCParticipantsSummaryHeaderCell", for: indexPath) as! ViewParticipantsSummaryHeaderCell
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCParticipantsCardCell", for: indexPath) as! ViewParticipantsCardCell
            cell.configure(with: participantsData[indexPath.row])
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummarySectionHeaderCell", for: indexPath) as! ViewSummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            cell.headerIcon.image = UIImage(systemName: "note.text")
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCNotesCardCell", for: indexPath) as! ViewNotesCardCell
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
