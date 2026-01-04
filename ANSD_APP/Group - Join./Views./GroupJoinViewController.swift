//
//  GroupJoinViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit

class GroupJoinViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var GJcollectionView: UICollectionView!
    @IBOutlet weak var GJpauseButton: UIButton!
    @IBOutlet weak var GJmicButton: UIButton!
    @IBOutlet weak var GJendButton: UIButton!
    
    var sessionTitle: String = "Conversation"
    var messages: [GJChatMessage] = []
    let fullConversation = GJChatData.fullConversation
    var currentMessageIndex = 0
    var isPaused = false
    var otherPersonName = "Person 1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = sessionTitle
        GJcollectionView.dataSource = self
        GJcollectionView.delegate = self
        
        if let layout = GJcollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.minimumLineSpacing = 4
            layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        }
        
        GJcollectionView.keyboardDismissMode = .interactive
        processNextMessage()
    }
    
    func processNextMessage() {
        if currentMessageIndex >= fullConversation.count { return }
        if isPaused { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            if self.isPaused { return }
            
            let message = self.fullConversation[self.currentMessageIndex]
            self.messages.append(message)
            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
            self.GJcollectionView.insertItems(at: [indexPath])
            self.scrollToBottom()
            self.currentMessageIndex += 1
            self.processNextMessage()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IncomingCell", for: indexPath) as! GJIncomingCell
            cell.GJmessageLabel.text = message.text
            
            if message.sender == "Person 1" {
                cell.GJnameLabel.text = self.otherPersonName
            } else {
                cell.GJnameLabel.text = message.sender
            }
            
            cell.onLabelTapped = { [weak self] in
                self?.showRenameAlert()
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutgoingCell", for: indexPath) as! GJOutgoingCell
            cell.GJmessageLabel.text = message.text
            return cell
        }
    }
    
    func showRenameAlert() {
        if !isPaused { togglePauseState() }
        
        let alert = UIAlertController(title: "Rename Speaker", message: "Enter name:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = self.otherPersonName
            tf.autocapitalizationType = .words
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self.otherPersonName = newName
                self.GJcollectionView.reloadData()
            }
            self.togglePauseState()
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    @IBAction func didTapPauseButton(_ sender: UIButton) {
        togglePauseState()
    }
    
    func togglePauseState() {
        isPaused = !isPaused
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imgName = isPaused ? "play.fill" : "pause.fill"
        GJpauseButton.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
        if !isPaused { processNextMessage() }
    }
    
    @IBAction func didTapStopButton(_ sender: UIButton) {
        if !isPaused { togglePauseState() }
        
        let actionSheet = UIAlertController(title: "End Session?", message: "Are you sure?", preferredStyle: .alert)
        let endAction = UIAlertAction(title: "End Session", style: .destructive) { _ in
            let storyboard = UIStoryboard(name: "Group-Join.", bundle: nil)
            
            if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
               let summaryVC = summaryNav.topViewController as? GJSummaryViewController {
                
                summaryVC.conversationTitle = self.sessionTitle
                summaryVC.chatHistory = self.messages
                summaryVC.participantsData = [
                    GJParticipantData(
                        name: "Peter Parker",
                        summary: "Peter has finished his assignment and is informing his friends about the same. He has a family outing at 4 PM and cannot help."
                    ),
                    GJParticipantData(
                        name: "Bruce Banner",
                        summary: "Bruce is having fun at Steve's misfortune and he hasn't started doing it as well. He is very relaxed about the whole thing."
                    ),
                    GJParticipantData(
                        name: "Steve Parker",
                        summary: "Steve is being smug about the whole thing and is scolding his friends for not having done the assignment in the past 3 weeks."
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
    
    func scrollToBottom() {
        guard messages.count > 0 else { return }
        GJcollectionView.scrollToItem(at: IndexPath(item: messages.count - 1, section: 0), at: .bottom, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - 32, height: 100)
    }
}
