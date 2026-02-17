//
//  SummaryCells.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 25/11/25.
//

import UIKit

// MARK: - Protocols
protocol PastNotesCardCellDelegate: AnyObject {
    func didUpdateText(in cell: NotesCardCell)
}

// MARK: - Styling Helper
private func styleCard(view: UIView?) {
    
    guard let card = view else { return }
    card.layer.cornerRadius = 12
    card.backgroundColor = .white

    card.layer.shadowColor = UIColor.black.cgColor
    card.layer.shadowOpacity = 0.05
    card.layer.shadowOffset = CGSize(width: 0, height: 2)
    card.layer.shadowRadius = 4
}

// MARK: - Headers
class SummarySectionHeaderCell: UITableViewCell {
    @IBOutlet weak var headerIcon: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

class ParticipantsSummaryHeaderCell: UITableViewCell {
    @IBOutlet weak var participantIcon: UIImageView!
    @IBOutlet weak var participantLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

// MARK: - 1. Conversation Card (Read-Only Title)
class SummaryCardCell: UITableViewCell {
    
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
    }
}

// MARK: - 2. Participant Card (Display Label)
class ParticipantCardCell: UITableViewCell {
    
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
        
        avatarImageView.layer.cornerRadius = 4
        avatarImageView.clipsToBounds = true
        avatarImageView.tintColor = .systemGray
    }
    
    func configure(with data: ParticipantData) {
        detailsLabel.text = data.summary
        
        if let image = UIImage(named: data.imageName) {
            avatarImageView.image = image
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
}

// MARK: - 3. Notes Card
class NotesCardCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var notesTextView: UITextView!
    
    weak var delegate: PastNotesCardCellDelegate?
    let placeholderText = "Add notes about this conversation..."
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        styleCard(view: mainCardView)
        
        notesTextView.delegate = self
        notesTextView.text = placeholderText
        notesTextView.textColor = .lightGray
        notesTextView.font = UIFont.systemFont(ofSize: 15)
        notesTextView.isScrollEnabled = false
        
        notesTextView.textContainerInset = .zero
        notesTextView.textContainer.lineFragmentPadding = 0
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
