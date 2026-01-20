//
//  QuickCaptioningViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit

class QuickCaptioningViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    var messages: [QCChatMessage] = []
    let fullConversation = QCChatData.fullConversation
    
    var currentMessageIndex = 0
    var isPaused = false
    var otherPersonName = "Person 1"
    
    // Function - Initializes the view lifecycle, setting up delegates, layout properties, and starting the message simulation.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.minimumLineSpacing = 4
            layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        }
        
        collectionView.keyboardDismissMode = .interactive
        processNextMessage()
    }
    
    // MARK: - Animation Logic
    
    // Function - Recursively processes and displays the next message in the conversation queue with a delay, respecting the pause state.
    private func processNextMessage() {
        if currentMessageIndex >= fullConversation.count { return }
        if isPaused { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            if self.isPaused { return }
            
            let message = self.fullConversation[self.currentMessageIndex]
            self.messages.append(message)
            
            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
            self.collectionView.insertItems(at: [indexPath])
            self.scrollToBottom()
            
            self.currentMessageIndex += 1
            self.processNextMessage()
        }
    }
    
    // MARK: - CollectionView DataSource
    
    // Function - Returns the total number of message items currently displayed in the collection view.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // Function - Dequeues and configures the appropriate cell type (incoming or outgoing) based on the message sender.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QCIncomingCell", for: indexPath) as! QCIncomingCell
            cell.messageLabel.text = message.text
            
            if message.sender == "Person 1" {
                cell.nameLabel.text = self.otherPersonName
            } else {
                cell.nameLabel.text = message.sender
            }
            
            cell.onLabelTapped = { [weak self] in
                self?.showRenameAlert()
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QCOutgoingCell", for: indexPath) as! QCOutgoingCell
            cell.QCmessageLabel.text = message.text
            return cell
        }
    }
    
    // MARK: - Rename Alert
    
    // Function - Displays an alert allowing the user to rename the other participant, pausing the simulation during input.
    private func showRenameAlert() {
        if !isPaused { togglePauseState() }
        
        let alert = UIAlertController(title: "Rename Speaker", message: "Enter name:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = self.otherPersonName
            tf.autocapitalizationType = .words
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self.otherPersonName = newName
                self.collectionView.reloadData()
            }
            self.togglePauseState()
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }

    // MARK: - Button Actions
    
    // Function - Action triggered when the pause button is tapped, calling the toggle state logic.
    @IBAction func didTapPauseButton(_ sender: UIButton) {
        togglePauseState()
    }
    
    // Function - Toggles the paused state of the message simulation and updates the button icon accordingly.
    private func togglePauseState() {
        isPaused = !isPaused
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imgName = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
        
        if !isPaused { processNextMessage() }
    }

    // Function - Action triggered when the stop button is tapped; pauses the session and presents a confirmation alert to end the session.
    @IBAction func didTapStopButton(_ sender: UIButton) {
        if !isPaused { togglePauseState() }
        
        let actionSheet = UIAlertController(title: "End Session?", message: "Are you sure?", preferredStyle: .alert)
        
        let endAction = UIAlertAction(title: "End Session", style: .destructive) { _ in
            let storyboard = UIStoryboard(name: "Quick Captions", bundle: nil)
            
            if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
               let summaryVC = summaryNav.topViewController as? SummaryViewController {
                
                let passedName = self.otherPersonName
                summaryVC.participantsData = [
                    QCParticipantData(
                        name: passedName,
                        summary: "\(passedName) is a cab driver who inquired about drop-off locations."
                    ),
                    QCParticipantData(
                        name: "Steve",
                        summary: "Steve provided the gate code (1322 5669) and building number (C4)."
                    )
                ]

                summaryNav.modalPresentationStyle = .pageSheet
                self.present(summaryNav, animated: true, completion: nil)
            }
        }
        
        actionSheet.addAction(endAction)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(actionSheet, animated: true)
    }

    // MARK: - Layout Helpers
    
    // Function - Automatically scrolls the collection view to the bottom-most item to show the latest message.
    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        collectionView.scrollToItem(at: IndexPath(item: messages.count - 1, section: 0), at: .bottom, animated: true)
    }
    
    // Function - Returns the size for each item in the collection view.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 100)
    }
}
