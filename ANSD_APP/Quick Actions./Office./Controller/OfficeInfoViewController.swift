//
//  InfoViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 07/12/25.
//

import UIKit

class OfficeInfoViewController: UIViewController, UITextViewDelegate {
    var existingNote: String?
    var onSave: ((String) -> Void)?
    
    @IBOutlet weak var notesTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notesTextView.delegate = self
        notesTextView.layer.cornerRadius = 12
        notesTextView.layer.borderWidth = 0.5
        notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
        
        if let safeNote = existingNote, !safeNote.isEmpty {
            notesTextView.text = safeNote
            notesTextView.textColor = .label
            notesTextView.tag = 0
        } else {
            notesTextView.text = "Add conversation notes here..."
            notesTextView.textColor = .lightGray
            notesTextView.tag = 999
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.tag == 999 {
            textView.text = nil
            textView.textColor = .label
            textView.tag = 0
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Add conversation notes here..."
            textView.textColor = .lightGray
            textView.tag = 999
        }
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let textToSave = (notesTextView.tag == 999) ? "" : notesTextView.text ?? ""
        print("💾 InfoVC is closing. Attempting to save: '\(textToSave)'")
        onSave?(textToSave)
    }
}
