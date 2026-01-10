//
//  ChatHistoryViewController.swift
//  ANSD_APP
//
//  Created by SDC-USER on 16/12/25.
//

import UIKit

class ChatHistoryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var chatContainerView: UIView!
    @IBOutlet var summaryContainerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var menuButton: UIBarButtonItem!
    
    var histconversationData: Conversation?
    var isHighlightModeActive = false
    
    var transcript: [Message] { histconversationData?.messages ?? [] }
    var participants: [PCParticipantData] { histconversationData?.participants ?? [] }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateContainerViews()
    }
    
    // Configures navigation title and sets up table view and collection view
    private func setupUI() {
        navigationItem.title = histconversationData?.title ?? "Details"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        
        collectionView.delegate = self
        collectionView.dataSource = self
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }

    // Switches between chat and summary views based on segmented control
    @IBAction func chatNsumSegmentedController(_ sender: UISegmentedControl) {
        view.endEditing(true)
        updateContainerViews()
    }
    
    // Shows or hides container views and reloads appropriate data
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
    
    // Returns the number of messages in the transcript
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return transcript.count
    }
    
    // Configures and returns a cell for each chat message
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatMessageCell", for: indexPath)
        return cell
    }
}

extension ChatHistoryViewController: UITableViewDataSource, UITableViewDelegate, PCNotesCardCellDelegate {
    
    // Returns the number of sections in the summary table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    // Returns the number of rows for each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 { return participants.count }
        return 1
    }
    
    // Configures and returns cells for each section in the summary view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummarySectionHeaderCell", for: indexPath) as! PCSummarySectionHeaderCell
            cell.headerLabel.text = "Summary"
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummaryCardCell", for: indexPath) as! PCSummaryCardCell
            cell.titleTextField.text = histconversationData?.title
            return cell
            
        case 2:
            return tableView.dequeueReusableCell(withIdentifier: "PCParticipantsSummaryHeaderCell", for: indexPath)
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCParticipantsCardCell", for: indexPath) as! PCParticipantsCardCell
            cell.configure(with: participants[indexPath.row])
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCSummarySectionHeaderCell", for: indexPath) as! PCSummarySectionHeaderCell
            cell.headerLabel.text = "Notes"
            return cell
            
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PCNotesCardCell", for: indexPath) as! PCNotesCardCell
            cell.notesTextView.text = histconversationData?.notes ?? ""
            cell.delegate = self
            return cell
            
        default: return UITableViewCell()
        }
    }
    
    // Updates conversation notes when user edits text and adjusts cell height
    func didUpdateText(in cell: PCNotesCardCell) {
        histconversationData?.notes = cell.notesTextView.text
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
