//
//  InfoViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 07/12/25.
//

import UIKit

// We conform to UITextViewDelegate so we can detect when the user starts/stops typing
class OfficeInfoViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - Properties
    
    // 1. DATA RECEIVER: This variable holds the note text sent FROM the main screen.
    var existingNote: String?
    
    // 2. DATA SENDER: This is a "Closure" (a function stored in a variable).
    // It allows us to send the updated note back to the main screen when this screen closes.
    var onSave: ((String) -> Void)?
    
    // 3. OUTLET: Connection to the text box on the storyboard so we can change its text/color.
    
    @IBOutlet weak var notesTextView: UITextView!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // 1. Force Delegate (CRITICAL for the tap-to-clear to work)
            notesTextView.delegate = self
            
            // 2. Styling
            notesTextView.layer.cornerRadius = 12
            notesTextView.layer.borderWidth = 0.5
            notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
            
            // 3. LOGIC: Decide State (Saved Note vs Placeholder)
            
            if let safeNote = existingNote, !safeNote.isEmpty {
                // CASE A: We have a saved note -> Load it in BLACK
                notesTextView.text = safeNote
                notesTextView.textColor = .label
                notesTextView.tag = 0 // Tag 0 = "Real Text Mode"
                
            } else {
                // CASE B: No note -> Load Placeholder in GRAY
                notesTextView.text = "Add conversation notes here..."
                notesTextView.textColor = .lightGray
                notesTextView.tag = 999 // Tag 999 = "Placeholder Mode"
            }
        
            // Styling...
                notesTextView.layer.cornerRadius = 12
                notesTextView.layer.borderWidth = 0.5
                notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
            }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
                // If the tag is 999, it means we are showing the placeholder
            if textView.tag == 999 { // If currently in Placeholder mode
                        textView.text = nil          // Clear text
                        textView.textColor = .label  // Switch to Black
                        textView.tag = 0             // Switch to Real Text Mode
                    }
            }

    func textViewDidEndEditing(_ textView: UITextView) {
        // If the box is empty or just whitespace
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Add conversation notes here..."
            textView.textColor = .lightGray
            textView.tag = 999           // Switch back to Placeholder Mode
        }
    }
    
    //MARK: - Actions & Navigation
    // Connected to the "X" button in the top-left corner.
    @IBAction func closeButtonTapped(_ sender: Any) {
        // Dismisses (closes) this modal screen with an animation.
        dismiss(animated: true, completion: nil)
    }
    // This system function runs automatically right before the screen vanishes.
        // We use this to save data, ensuring it saves even if the user swipes down instead of clicking "X".
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            // LOGIC: Determine what text to save.
            // If Tag is 999 (Placeholder is visible), we save an empty string "".
            // If Tag is 0 (Real text), we save whatever is typed in the box.
            let textToSave = (notesTextView.tag == 999) ? "" : notesTextView.text ?? ""
            
            // Debugging: Print to console so we can verify saving is happening.
            print("💾 InfoVC is closing. Attempting to save: '\(textToSave)'")
            
            // Trigger the 'onSave' closure to send this text back to the Main Screen.
            onSave?(textToSave)
        }
    }
