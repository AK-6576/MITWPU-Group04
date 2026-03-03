//
//  GroupNewSummaryCells.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// MARK: - Protocols
protocol GroupNewNotesCardCellDelegate: AnyObject {
    func didUpdateText(in cell: GroupNewNotesCardCell)
}

protocol GroupNewSummaryCardDelegate: AnyObject {
    func didChangeTitle(text: String)
}

// MARK: - Helper Styling Function
private func styleCard(view: UIView?) {
    guard let card = view else { return }
    card.layer.cornerRadius = 12
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.shadowColor = UIColor.black.cgColor
    card.layer.shadowOpacity = 0.05
    card.layer.shadowOffset = CGSize(width: 0, height: 2)
    card.layer.shadowRadius = 4
}

// MARK: - 1. Section Header Cell
class GroupNewSummarySectionHeaderCell: UITableViewCell {
    @IBOutlet weak var headerIcon: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

// MARK: - 2. Participants Card Cell (NEW)
class GroupNewParticipantsCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
        
        // Avatar Styling
        if let avatar = avatarImageView {
            avatar.layer.cornerRadius = avatar.frame.height / 2
            avatar.clipsToBounds = true
            avatar.backgroundColor = .systemGray5
            avatar.tintColor = .systemGray
            avatar.contentMode = .scaleAspectFill
        }
    }
    
    func configure(with data: GroupNewParticipantData) {
        summaryLabel.text = data.summary
        
        // Default Icon
        if avatarImageView.image == nil {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
}

// MARK: - 3. Main Summary Card (Title, Date, Location)
class GroupNewSummaryCardCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    weak var delegate: GroupNewSummaryCardDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
        titleTextField.delegate = self
    }
    
    func configure(title: String, date: String, time: String, location: String) {
        titleTextField.text = title
        dateLabel.text = date
        timeLabel.text = time
        locationLabel.text = location
    }
    
    @IBAction func titleChanged(_ sender: UITextField) {
        delegate?.didChangeTitle(text: sender.text ?? "")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 4. Notes Card Cell (AI Output)
class GroupNewNotesCardCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var notesTextView: UITextView!
    
    weak var delegate: GroupNewNotesCardCellDelegate?
    let placeholderText = "Add notes about this conversation..."
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
        
        notesTextView.delegate = self
        notesTextView.isScrollEnabled = false
        notesTextView.textContainerInset = .zero
        notesTextView.textContainer.lineFragmentPadding = 0
        notesTextView.font = UIFont.systemFont(ofSize: 15)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = nil
            textView.textColor = UIColor.label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholderText
            textView.textColor = .lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        delegate?.didUpdateText(in: self)
    }
}
