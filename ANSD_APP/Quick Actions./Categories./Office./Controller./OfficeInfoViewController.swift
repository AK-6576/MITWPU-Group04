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
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
