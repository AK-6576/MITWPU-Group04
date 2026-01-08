import UIKit

// MARK: - Protocols
protocol PCNotesCardCellDelegate: AnyObject {
    func didUpdateText(in cell: PCNotesCardCell)
}

protocol PCSummaryCardDelegate: AnyObject {
    func didChangeTitle(text: String)
}

// MARK: - Custom TableView Cell Classes

class PCSummarySectionHeaderCell: UITableViewCell {
    @IBOutlet weak var headerIcon: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

class PCParticipantsSummaryHeaderCell: UITableViewCell {
    @IBOutlet weak var participantIcon: UIImageView!
    @IBOutlet weak var participantLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

class PCNotesSectionHeaderCell: UITableViewCell {
    @IBOutlet weak var notesIcon: UIImageView!
    @IBOutlet weak var notesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

class PCSummaryCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    weak var delegate: PCSummaryCardDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        // Note: Ensure styleCard is defined in your project
        // styleCard(view: mainCardView)
    }
    
    @IBAction func titleChanged(_ sender: UITextField) {
        delegate?.didChangeTitle(text: sender.text ?? "")
    }
}

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
        // styleCard(view: mainCardView)
    }
    
    func configure(with data: PCParticipantData) {
        detailsLabel.text = data.summary
    }
}

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
        // styleCard(view: mainCardView)
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
class chatHistory2ViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var chatContainerView: UIView!
    @IBOutlet var summaryContainerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    let emptyChatLabel = UILabel()
    var histconversationData: Conversation?
    var isHighlightModeActive = false
    var conversationTitle = "Conversation Summary"
    var participantsData: [PCParticipantData] = []
    
    var transcript: [Message] {
        return histconversationData?.messages ?? []
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupChatUI()
        setupSummaryUI()
        setupMenu()
        updateContainerViews()
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
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
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
        setupMenu()
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
    
    func scrollToBottom(animated: Bool = true) {
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

    func setupMenu() {
        let isChatSelected = (segmentedControl.selectedSegmentIndex == 0)
        
        let highlightAction = UIAction(title: isHighlightModeActive ? "Stop Highlighting" : "Highlight Text",
                                       image: UIImage(systemName: "highlighter")) { _ in
            self.isHighlightModeActive.toggle()
            self.collectionView.reloadData()
            self.setupMenu()
        }
        
        let editAction = UIAction(title: "Edit Mode", image: UIImage(systemName: "pencil")) { _ in
            let alert = UIAlertController(title: "Edit Mode", message: "Tap any message bubble to edit.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
        
        let exportAction = UIAction(title: "Share Summary PDF", image: UIImage(systemName: "doc.plaintext")) { _ in
            self.shareAsPDF()
        }

        if isChatSelected {
            menuButton.menu = UIMenu(title: "", children: [highlightAction, editAction, exportAction])
        } else {
            menuButton.menu = UIMenu(title: "", children: [exportAction])
        }
    }

    func showEditAlert(for indexPath: IndexPath) {
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

// MARK: - Collection View Logic
extension chatHistory2ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return transcript.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = transcript[indexPath.row]
        
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PCIncomingCell", for: indexPath) as! PC2IncomingViewCell
            if message.isHighlighted {
                let textAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue, .underlineColor: UIColor.black]
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
                let textAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue, .underlineColor: UIColor.white]
                cell.PCmessageLabel.attributedText = NSAttributedString(string: message.text, attributes: textAttributes)
            } else {
                cell.PCmessageLabel.attributedText = nil
                cell.PCmessageLabel.text = message.text
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

// MARK: - Table View & Text Management
extension chatHistory2ViewController: UITableViewDelegate, UITableViewDataSource, PCSummaryCardDelegate, PCNotesCardCellDelegate {
    
    // Protocol method for PCNotesCardCellDelegate
    func didUpdateText(in cell: PCNotesCardCell) {
        // If it's not the placeholder, save to data
        if cell.notesTextView.text != cell.placeholderText {
            self.histconversationData?.notes = cell.notesTextView.text
            
            // Dynamic height adjustment
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummarySectionHeaderCell", for: indexPath) as! PCSummarySectionHeaderCell
            cell.headerLabel.text = "Summary"
            cell.headerIcon.image = UIImage(systemName: "text.alignleft")
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

// MARK: - PDF Logic
extension chatHistory2ViewController {
    func shareAsPDF() {
        var pdfContent = "Title: \(conversationTitle)\n\n"
        for person in participantsData {
            pdfContent += "\(person.name): \(person.summary)\n"
        }
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        let data = renderer.pdfData { (context) in
            context.beginPage()
            pdfContent.draw(in: CGRect(x: 20, y: 20, width: 555, height: 802), withAttributes: nil)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Summary.pdf")
        try? data.write(to: tempURL)
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}
