//
//  ChatHistoryViewController.swift
//  ANSD_APP
//
//  Created by SDC-USER on 15/12/25.
//

import UIKit

class ChatHistoryViewController: UIViewController {
    
    
    var histconversationData: Conversation!
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    @IBOutlet var chatContainerView: UIView!
    
    @IBOutlet var summaryContainerView: UIView!
    
    @IBOutlet var chatPlaceholderLabel: UILabel!
    
    @IBOutlet var summaryPlaceholderLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let convoData = histconversationData {
            navigationItem.title = convoData.title
            
            
            chatPlaceholderLabel.text = "Chat Transcript for: \(convoData.title)\n\n(This is where the Chat View Controller goes)"
            
            // You'll need to update this to actually load/display the summary
            summaryPlaceholderLabel.text = "Summary for: \(convoData.title)\n\n(This is where the Summary View Controller goes)"
        }
        
        // 3. Initial Setup
        setupSegmentedControl()
        updateContainerViews()
        
        
        
        
    }
    private func setupSegmentedControl() {
        // Ensure the segmented control has the correct titles if not set in Storyboard
        // Assuming: Index 0 is Chat, Index 1 is Summary
        if segmentedControl.numberOfSegments < 2 {
            segmentedControl.removeAllSegments()
            segmentedControl.insertSegment(withTitle: "Chat", at: 0, animated: false)
            segmentedControl.insertSegment(withTitle: "Summary", at: 1, animated: false)
        }
        segmentedControl.selectedSegmentIndex = 0 // Start on the Chat tab
    }
    
    private func updateContainerViews() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        // Show the Chat container if index is 0, hide otherwise
        chatContainerView.isHidden = (selectedIndex != 0)
        
        // Show the Summary container if index is 1, hide otherwise
        summaryContainerView.isHidden = (selectedIndex != 1)
        
        // FUTURE ENHANCEMENT: This is where you would load/display the embedded View Controllers (the actual chat and summary views)
    }
    
    // MARK: - Actions
    
    @IBAction func chatNsumSegmentedController(_ sender: UISegmentedControl) {
        // Call the function to switch the visible container view
        updateContainerViews()
        
        /*
         // MARK: - Navigation
         
         // In a storyboard-based application, you will often want to do a little preparation before navigation
         override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
         }
         */
        
    }
}
