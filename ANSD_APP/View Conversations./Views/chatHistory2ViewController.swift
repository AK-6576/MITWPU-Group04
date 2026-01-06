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

        // MARK: - Actions
        @IBAction func chatNsumSegmentedController(_ sender: UISegmentedControl) {
            view.endEditing(true) // Dismiss keyboard when switching
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
        
        func setupMenu() {
            let exportAction = UIAction(title: "Share Summary PDF", image: UIImage(systemName: "doc.plaintext")) { _ in
                self.shareAsPDF()
            }
            menuButton.menu = UIMenu(title: "", children: [exportAction])
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
                cell.messageLabel.text = message.text
                cell.nameLabel.text = message.senderName
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PCOutCell", for: indexPath) as! PCOutgoing2Cell
                cell.PCmessageLabel.text = message.text
                return cell
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: collectionView.bounds.width, height: 100)
        }
    }

    // MARK: - Table View (Summary Logic)
    extension chatHistory2ViewController: UITableViewDelegate, UITableViewDataSource, QCNotesCardCellDelegate, QCSummaryCardDelegate {
        
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
                cell.delegate = self
                return cell
            default:
                return UITableViewCell()
            }
        }
        
        // Delegate Methods
        func didUpdateText(in cell: QCNotesCardCell) {
            tableView.performBatchUpdates(nil)
        }
        
        func didChangeTitle(text: String) {
            conversationTitle = text
        }
    }

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
