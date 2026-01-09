//
//  GroupNewViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit

class GroupNewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    var messages: [GNChatMessage] = []
    let fullConversation = GNChatData.fullConversation
    var currentMessageIndex = 0
    var isPaused = false
    var otherPersonName = "Person 1"
    
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
    
    // MARK: - Helper to match Names to Avatar Assets
    func getImageName(for name: String) -> String {
        let lowerName = name.lowercased()
        
        if lowerName.contains("steve") { return "avatar_1" }
        if lowerName.contains("peter") { return "avatar_2" }
        if lowerName.contains("bruce") { return "avatar_3" }
        if lowerName.contains("tony") { return "avatar_4" }
        if lowerName.contains("natasha") { return "avatar_5" }
        if lowerName.contains("wanda") { return "avatar_6" }
        if lowerName.contains("vision") { return "avatar_7" }
        if lowerName.contains("bucky") { return "avatar_8" }
        
        // Fallback
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
    
    // MARK: - CollectionView Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IncomingCell", for: indexPath) as! GNIncomingCell
            
            cell.messageLabel.text = message.text
            
            // Determine the display name
            let displayName: String
            if message.sender == "Person 1" {
                displayName = self.otherPersonName
            } else {
                displayName = message.sender
            }
            
            cell.nameLabel.text = displayName
            
            // Set the Profile Image based on the updated Avatar logic
            let imageName = getImageName(for: displayName)
            if let image = UIImage(named: imageName) {
                cell.profileImageView.image = image
            } else {
                cell.profileImageView.image = UIImage(systemName: "person.circle.fill")
            }
            
            cell.onLabelTapped = { [weak self] in
                self?.showRenameAlert()
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutgoingCell", for: indexPath) as! GNOutgoingCell
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
            let storyboard = UIStoryboard(name: "Group-New.", bundle: nil)
            
            if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
               let summaryVC = summaryNav.topViewController as? GNSummaryViewController {
                
                // Updated Summary Data with new Avatar names
                summaryVC.participantsData = [
                    GNParticipantData(
                        name: "Peter",
                        summary: "Peter has gotten a look at some alleged photos from the set of Avengers Doomsday, and thinks that they are real.",
                        imageName: "avatar_2" // Updated from peter_parker
                    ),
                    GNParticipantData(
                        name: "Bruce",
                        summary: "Bruce thinks that they are either a photo-shop, and his words imply that he doesn't believe it to be genuine.",
                        imageName: "avatar_3" // Updated from bruce_banner
                    ),
                    GNParticipantData(
                        name: "Steve",
                        summary: "Steve has dismissed it as fan-fiction or an image generated by Google Gemini.",
                        imageName: "avatar_1" // Updated from steve_rogers
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
        let lastItem = IndexPath(item: messages.count - 1, section: 0)
        self.collectionView.scrollToItem(at: lastItem, at: .bottom, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 100)
    }
    
    @IBAction func addPersonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Group-New.", bundle: nil)
        
        if let selectionVC = storyboard.instantiateViewController(withIdentifier: "ParticipantSelectionViewController") as? ParticipantSelectionViewController {
            // Updated unavailable list to match potential logic
            selectionVC.unavailableContacts = ["Peter", "Bruce"]
            selectionVC.onPeopleAdded = { newNames in
                print("User added: \(newNames)")
            }
            
            let navWrapper = UINavigationController(rootViewController: selectionVC)
            navWrapper.modalPresentationStyle = .pageSheet
            if let sheet = navWrapper.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
            
            self.present(navWrapper, animated: true)
        }
    }
}
