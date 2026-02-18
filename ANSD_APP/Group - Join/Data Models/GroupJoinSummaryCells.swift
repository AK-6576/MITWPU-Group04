//
//  GroupJoinSummaryCells.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
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
    func configure(with data: GroupJoinParticipants) {
        summaryLabel.text = data.summary
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
    }
}

// MARK: - CHANGED: Title is now a UILabel (Read Only)
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
