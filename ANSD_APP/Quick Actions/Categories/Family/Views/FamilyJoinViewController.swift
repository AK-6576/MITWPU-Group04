//
//  FamilyJoinViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 25/11/25.
//

import UIKit

class FamilyJoinViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    var sessionTitle: String = "Breakfast"
    var messages: [FamilyChat] = []
    let fullConversation = FamilyChatParticipants.fullConversation
    var currentMessageIndex = 0
    var isPaused = false
    var otherPersonName = "Person 1"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = sessionTitle
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
    
    // MARK: - Image Helper
    func getImageName(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("marie") { return "avatar_9" }
        if lower.contains("henry") { return "avatar_10" }
        if lower.contains("anna") { return "avatar_7" }
        return "person.circle.fill"
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
            self.collectionView.insertItems(at: [indexPath])
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IncomingCell", for: indexPath) as! IncomingCell1
            cell.messageLabel.text = message.text
            

            let displayName: String
            if message.sender == "Person 1" {
                displayName = self.otherPersonName
            } else {
                displayName = message.sender
            }
            cell.nameLabel.text = displayName
            
            let imgName = getImageName(for: displayName)
            if let image = UIImage(named: imgName) {
                cell.profileImageView.image = image
            } else {
                cell.profileImageView.image = UIImage(systemName: "person.circle.fill")
            }
            
            cell.onLabelTapped = { [weak self] in
                self?.showRenameAlert()
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutgoingCell", for: indexPath) as! OutgoingCell1
            cell.messageLabel.text = message.text
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
                self.collectionView.reloadData()
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
        pauseButton.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
        if !isPaused { processNextMessage() }
    }
    
    @IBAction func didTapStopButton(_ sender: UIButton) {
        if !isPaused { togglePauseState() }
        
        let actionSheet = UIAlertController(title: "End Session?", message: "Are you sure?", preferredStyle: .alert)
        let endAction = UIAlertAction(title: "End Session", style: .destructive) { _ in

            let storyboard = UIStoryboard(name: "Family.", bundle: nil)
            
            if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
               let summaryVC = summaryNav.topViewController as? FamilySummaryViewController {
                
                summaryVC.conversationTitle = self.sessionTitle
                summaryVC.chatHistory = self.messages
                summaryVC.participantsData = [
                    FamilyParticipantData(
                        name: "Marie Parker",
                        summary: "Marie announced that pancakes were ready and reminded everyone about the 10 AM dentist appointment. She also expressed concern about Anna missing the bus."
                    ),
                    FamilyParticipantData(
                        name: "Henry Parker",
                        summary: "Henry complimented the breakfast and offered a ride to the dentist appointment. He suggested letting Anna sleep in longer since she was up late studying."
                    ),
                    FamilyParticipantData(
                        name: "Me",
                        summary: "I confirmed I would be down shortly and accepted Dad's offer for a ride to save money on an Uber. I also jokingly reminded them to save pancakes for Anna."
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
    
    // MARK: - Info Button Logic
    @IBAction func didTapInfoButton(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowInfo", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowInfo" {
            let destinationVC = segue.destination
            if let sheet = destinationVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
    }
    
    func scrollToBottom() {
        guard messages.count > 0 else { return }
        collectionView.scrollToItem(at: IndexPath(item: messages.count - 1, section: 0), at: .bottom, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 100)
    }
}
