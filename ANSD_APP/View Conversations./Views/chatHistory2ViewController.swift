//
//  chatHistory2ViewController.swift
//  ANSD_APP
//
//  Created by SDC-USER on 06/01/26.
//

import UIKit

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
        // Summary Data
        var conversationTitle = "Conversation Summary"
        var participantsData: [QCParticipantData] = []
        
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
            // These delegates are now handled by this class
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
            tableView.backgroundColor = .clear
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 120
            
            // Setup Participants Data if available
            // participantsData = histconversationData?.participants ?? []
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
            view.endEditing(true) // Dismiss keyboard when switching
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
        
        // MARK: - Helper Methods
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
    func setupChatContainerView(){
            chatContainerView.layer.cornerRadius = 20
            chatContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        // collection view corner radius is set in cchat logic below
        }
    // MARK: - Menu Button setup
    func setupMenu() {
        let isChatSelected = (segmentedControl.selectedSegmentIndex == 0)
        
        // 1. HIGHLIGHT ACTION
        let highlightAction = UIAction(title: isHighlightModeActive ? "Stop Highlighting" : "Highlight Text",
                                       image: UIImage(systemName: "highlighter")) { _ in
            self.isHighlightModeActive.toggle()
            // We reload to show a visual cue (like a change in background color) that we are in "Selection Mode"
            self.collectionView.reloadData()
            self.setupMenu() // Refresh menu title to show "Stop Highlighting"
        }
        
        // 2. EDIT ACTION
        let editAction = UIAction(title: "Edit Mode", image: UIImage(systemName: "pencil")) { _ in
            // Option: Show an alert telling user to "Tap a bubble to edit" or "Long press to edit"
            let alert = UIAlertController(title: "Edit Mode", message: "Tap any message bubble to edit its text.", preferredStyle: .alert)
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
                // Update the source data directly
                self.histconversationData?.messages?[indexPath.row].text = newText
                
                // Refresh the UI
                self.collectionView.reloadItems(at: [indexPath])
                
                // Notify other screens
                self.notifyDataChanged()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    }

    // MARK: - Collection View (Chat Logic)
    extension chatHistory2ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return transcript.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let message = transcript[indexPath.row]
            
            if message.isIncoming {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PCIncomingCell", for: indexPath) as! PC2IncomingViewCell
                
                if message.isHighlighted {
                    let textAttributes: [NSAttributedString.Key: Any] = [
                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                        .underlineColor: UIColor.black // You can change the color of the line here
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
                        .underlineColor: UIColor.white // White looks better on the blue outgoing bubble
                    ]
                    cell.PCmessageLabel.attributedText = NSAttributedString(string: message.text, attributes: textAttributes)
                } else {
                    cell.PCmessageLabel.attributedText = nil
                    cell.PCmessageLabel.text = message.text
                }
                
                return cell
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            collectionView.layer.cornerRadius = 20
            return CGSize(width: collectionView.bounds.width, height: 100)
            
        }
        func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                
                // HIGHLIGHT ACTION
                let highlight = UIAction(title: "Highlight", image: UIImage(systemName: "highlighter")) { _ in
                    // 1. Toggle the value in the actual source data
                    let currentStatus = self.histconversationData?.messages?[indexPath.row].isHighlighted ?? false
                    self.histconversationData?.messages?[indexPath.row].isHighlighted = !currentStatus
                    
                    // 2. Reload the cell to apply the yellow color immediately
                    collectionView.reloadItems(at: [indexPath])
                    
                    // 3. Notify other screens (Real-time update)
                    self.notifyDataChanged()
                }
                
                // EDIT ACTION
                let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
                    self.showEditAlert(for: indexPath)
                }
                
                return UIMenu(title: "", children: [highlight, edit])
            }
        
        }
    }

    // MARK: - Table View (Summary Logic)
extension chatHistory2ViewController: UITableViewDelegate, UITableViewDataSource, QCNotesCardCellDelegate, QCSummaryCardDelegate {
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
                return tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QCSummarySectionHeaderCell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCardCell", for: indexPath) as! QCSummaryCardCell
                cell.titleTextField.text = conversationTitle
                cell.delegate = self
                return cell
            case 2:
                return tableView.dequeueReusableCell(withIdentifier: "ParticipantsSummaryHeaderCell", for: indexPath) as! QCParticipantsSummaryHeaderCell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantsCardCell", for: indexPath) as! QCParticipantCardCell
                cell.configure(with: participantsData[indexPath.row])
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SummarySectionHeaderCell", for: indexPath) as! QCSummarySectionHeaderCell
                cell.headerLabel.text = "Notes"
                cell.headerIcon.image = UIImage(systemName: "note.text")
                return cell
            case 5:
                let cell = tableView.dequeueReusableCell(withIdentifier: "NotesCardCell", for: indexPath) as! QCNotesCardCell
               
                cell.notesTextView.delegate = self
                
                cell.notesTextView.text = histconversationData?.notes ?? ""
                
                return cell
        }
        func didUpdateText(in cell: QCNotesCardCell, newText: String) {
                // 1. Update the actual data model
                self.histconversationData?.notes = newText
                
                // 2. Refresh table height for auto-expanding text views
                tableView.performBatchUpdates(nil)
                
                // 3. Notify app of data change (Persists the change)
                self.notifyDataChanged()
            }
            
            // Fallback for your existing version of the delegate if you can't change the protocol
            func didUpdateText(in cell: QCNotesCardCell) {
                if let newText = cell.notesTextView.text {
                    self.histconversationData?.notes = newText
                    self.notifyDataChanged()
                }
                tableView.performBatchUpdates(nil)
            }    }

    // MARK: - PDF Logic
    extension chatHistory2ViewController {
        func shareAsPDF() {
            var pdfContent = "Title: \(conversationTitle)\n\n"
            for person in participantsData {
                pdfContent += "\(person.name): \(person.summary)\n"
            }
            
            // PDF Generation Logic...
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
