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

protocol GroupJoinSummaryCardDelegate: AnyObject {
    func didChangeTitle(text: String)
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
}

// NEW CARD CELL (Matches Group New)
class GroupJoinParticipantsCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
        avatarImageView?.layer.cornerRadius = (avatarImageView?.frame.height ?? 40) / 2
        avatarImageView?.clipsToBounds = true
    }
    
    func configure(with data: GroupJoinParticipants) {
        nameLabel.text = data.name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        summaryLabel.text = data.summary
        summaryLabel.textColor = .secondaryLabel
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
    }
}

class GroupJoinSummaryCardCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    weak var delegate: GroupJoinSummaryCardDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
        titleTextField?.delegate = self
    }
    
    func configure(title: String, date: String, time: String, location: String) {
        titleTextField?.text = title
        dateLabel?.text = date
        timeLabel?.text = time
        locationLabel?.text = location
    }
    
    @IBAction func titleChanged(_ sender: UITextField) {
        delegate?.didChangeTitle(text: sender.text ?? "")
    }
}

class GroupJoinNotesCardCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var notesTextView: UITextView!
    weak var delegate: GroupJoinNotesCardCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
        notesTextView.delegate = self
        notesTextView.isScrollEnabled = false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        delegate?.didUpdateText(in: self)
    }
}
