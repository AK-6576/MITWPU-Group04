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
    @IBOutlet var summaryPlaceholderLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
  
    @IBOutlet var menuButton: UIBarButtonItem!
    
    
    // MARK: Properties
        let emptyChatLabel = UILabel()
        var histconversationData: Conversation? // FIXED: Optional to prevent crashes if nil
        
        var transcript: [Message] {
            return histconversationData?.messages ?? []
        }
        
        // MARK: Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Navigation Setup
            if let convoData = histconversationData {
                navigationItem.title = convoData.title
                summaryPlaceholderLabel.text = "Summary for: \(convoData.title)\n\n(Summary View Here)"
            } else {
                navigationItem.title = "Chat History"
            }
            
            // Delegate/DataSource Setup
            setUpChatViewContainer()
            setupSegmentedControl()
            collectionView.delegate = self
            collectionView.dataSource = self
            setupMenu()
            
            // Collection View Flow Layout Configuration
            if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                // FIXED: Using automaticSize requires valid constraints inside your cells
                flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            }
            
            // View Setup
            setupEmptyChatLabel()
            updateContainerViews()
            
            collectionView.reloadData()
            updateEmptyState()
            
            // Scroll to Bottom
            if !transcript.isEmpty {
                DispatchQueue.main.async {
                    self.scrollToBottom(animated: false)
                }
            }
        }
        
        // MARK: Actions
        @IBAction func chatNsumSegmentedController(_ sender: UISegmentedControl) {
            updateContainerViews()
        }
        
        // MARK: Private Methods
        private func updateContainerViews() {
            let selectedIndex = segmentedControl.selectedSegmentIndex
            chatContainerView.isHidden = (selectedIndex != 0)
            summaryContainerView.isHidden = (selectedIndex != 1)
            if selectedIndex == 0 { updateEmptyState() }
        }
        
        private func setupEmptyChatLabel() {
            emptyChatLabel.translatesAutoresizingMaskIntoConstraints = false
            emptyChatLabel.text = "No chat transcript available."
            emptyChatLabel.textColor = .systemGray
            emptyChatLabel.textAlignment = .center
            emptyChatLabel.numberOfLines = 0
            chatContainerView.addSubview(emptyChatLabel)
            
            NSLayoutConstraint.activate([
                emptyChatLabel.centerXAnchor.constraint(equalTo: chatContainerView.centerXAnchor),
                emptyChatLabel.centerYAnchor.constraint(equalTo: chatContainerView.centerYAnchor),
                emptyChatLabel.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor, constant: 20),
                emptyChatLabel.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor, constant: -20)
            ])
        }

        func setupMenu() {
            let editAction = UIAction(title: "Edit Text", image: UIImage(systemName: "square.and.pencil")) { _ in
                print("Edit tapped")
            }
            let highlightAction = UIAction(title: "Highlight Text", image: UIImage(systemName: "highlighter")) { _ in
                print("Highlight tapped")
            }
            let exportAction = UIAction(title: "Export", image: UIImage(systemName: "square.and.arrow.up")) { _ in
                print("Export tapped")
            }

            let menu = UIMenu(title: "", children: [editAction, highlightAction, exportAction])
            menuButton.menu = menu
        }
        
        private func updateEmptyState() {
            let isEmpty = transcript.isEmpty
            collectionView.isHidden = isEmpty
            emptyChatLabel.isHidden = !isEmpty
        }
        
        private func setupSegmentedControl() {
            segmentedControl.selectedSegmentIndex = 0
        }
        
        func scrollToBottom(animated: Bool = true) {
            guard !transcript.isEmpty else { return }
            let lastItem = transcript.count - 1
            collectionView.scrollToItem(at: IndexPath(item: lastItem, section: 0), at: .bottom, animated: animated)
        }
        
        func setUpChatViewContainer() {
            // Additional UI styling if needed
        }
    }

    // MARK: - Collection View Delegate/Data Source
    // FIXED: Renamed extension to match the class name ChatHistory2ViewController
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
                // FIXED: Ensure class name PCOutgoingCell matches your actual cell class
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PCOutCell", for: indexPath) as! PCOutgoing2Cell
                cell.PCmessageLabel.text = message.text
                return cell
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            // FIXED: Do not set layer properties (shadows/corners) inside sizeForItemAt.
            // This method is called hundreds of times during scrolling and will cause lag.
            // Move those to viewDidLoad or a setup method.
            
            let width = collectionView.bounds.width
            // Return a width with a placeholder height;
            // FlowLayout will use estimatedItemSize to calculate the actual height.
            return CGSize(width: width, height: 100)
        }
    }
