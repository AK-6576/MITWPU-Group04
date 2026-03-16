//
//  GroupJoinSummaryCells.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

protocol GroupJoinNotesCardCellDelegate: AnyObject {
    func didUpdateText(in cell: GroupJoinNotesCardCell)
}

private func styleCard(view: UIView?) {
    guard let card = view else { return }
    card.layer.cornerRadius = 12
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.shadowColor = UIColor.black.cgColor
    card.layer.shadowOpacity = 0.05
    card.layer.shadowOffset = CGSize(width: 0, height: 2)
    card.layer.shadowRadius = 4
}

class GroupJoinSummarySectionHeaderCell: UITableViewCell {
    
    @IBOutlet weak var headerIcon: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

class GroupJoinParticipantsCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var summaryLabel: UILabel!
    
    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var initialsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        styleCard(view: mainCardView)

        avatarView?.layer.cornerRadius = 8
        avatarView?.clipsToBounds = true
    }

    func configure(with data: GroupJoinParticipants) {
        // Use Attributed Text to show Name (Bold) and Summary (Regular)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let combinedText = NSMutableAttributedString(string: "\(data.name)\n", attributes: nameAttributes)
        combinedText.append(NSAttributedString(string: data.summary, attributes: summaryAttributes))
        
        summaryLabel.attributedText = combinedText
        
        // Initials Logic
        let components = data.name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }.joined()
        initialsLabel?.text = String(initials.prefix(2)).uppercased()
        initialsLabel?.font = .systemFont(ofSize: 16, weight: .bold)

        let currentUserName = (UserDefaults.standard.string(forKey: "user_first_name") ?? "").lowercased()
        let speakerName = data.name.lowercased()

        if (!currentUserName.isEmpty && speakerName.contains(currentUserName)) || speakerName == "you" {
            avatarView?.backgroundColor = .systemBlue
            initialsLabel?.textColor = .white
        } else {
            avatarView?.backgroundColor = .systemGray4
            initialsLabel?.textColor = .label
        }
    }
}

// MARK: - Summary Card Cell (Read-Only Title)
class GroupJoinSummaryCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
    }
    
    func configure(title: String, date: String, time: String, location: String) {
        titleLabel?.text = title
        dateLabel?.text = date
        timeLabel?.text = time
        locationLabel?.text = location
    }
}

class GroupJoinNotesCardCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var notesTextView: UITextView!
    weak var delegate: GroupJoinNotesCardCellDelegate?
    
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
