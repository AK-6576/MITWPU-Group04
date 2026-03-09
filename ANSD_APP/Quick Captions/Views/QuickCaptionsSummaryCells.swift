//
//  QuickCaptionsSummaryCells.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// MARK: - Protocols
protocol QuickCaptionsNotesCardCellDelegate: AnyObject {
    func didUpdateText(in cell: QuickCaptionsNotesCardCell)
}

protocol QuickCaptionsSummaryCardDelegate: AnyObject {
    func didChangeTitle(text: String)
}

// MARK: - Helper Styling Function
private func styleCard(view: UIView?) {
    guard let card = view else { return }
    card.layer.cornerRadius = 12
    card.backgroundColor = .secondarySystemGroupedBackground
    
    // Soft shadow for the modern floating card effect
    card.layer.shadowColor = UIColor.black.cgColor
    card.layer.shadowOpacity = 0.06
    card.layer.shadowOffset = CGSize(width: 0, height: 3)
    card.layer.shadowRadius = 6
    card.layer.masksToBounds = false
}

// MARK: - 0. Section Header Cell
class QuickCaptionsSummarySectionHeaderCell: UITableViewCell {
    @IBOutlet weak var headerIcon: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

// MARK: - 1. Main Header Card (Title, Date, Location)
class QuickCaptionsSummaryCardCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    weak var delegate: QuickCaptionsSummaryCardDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        styleCard(view: mainCardView)
        
        titleTextField.delegate = self
        titleTextField.borderStyle = .none
    }
    
    func configure(title: String, date: String, time: String, location: String?) {
        titleTextField.text = title
        dateLabel.text = date
        timeLabel.text = time
        locationLabel.text = location ?? "Unknown Location"
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            delegate?.didChangeTitle(text: text)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 2. Participant Card (Initials & Summary)
class QuickCaptionsParticipantCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        styleCard(view: mainCardView)
    }
    
    func configure(with data: QuickCaptionsParticipantData) {
        summaryLabel.text = data.summary
        
        // Auto-generate initials
        let components = data.name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }.joined()
        initialsLabel.text = String(initials.prefix(2)).uppercased()
        
        // Blue for User (Steve), Gray for others
        if data.name.lowercased().contains("steve") {
            avatarView.backgroundColor = .systemBlue
            initialsLabel.textColor = .white
        } else {
            avatarView.backgroundColor = .systemGray4
            initialsLabel.textColor = .label
        }
    }
}

// MARK: - 3. Notes Card (Key Takeaways)
class QuickCaptionsNotesCardCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var notesTextView: UITextView!
    
    weak var delegate: QuickCaptionsNotesCardCellDelegate?
    let placeholderText = "Add notes about this conversation..."
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        styleCard(view: mainCardView)
        
        notesTextView.delegate = self
        notesTextView.isScrollEnabled = false // Vital for dynamic height
        notesTextView.textContainerInset = .zero
        notesTextView.textContainer.lineFragmentPadding = 0
        notesTextView.backgroundColor = .clear
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
        // Notifies SummaryViewController to resize the cell as typing happens
        delegate?.didUpdateText(in: self)
    }
}
