//
//  QCSummaryCells.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit

// MARK: - Protocols

// Delegate for handling text updates in notes card cells
protocol QCNotesCardCellDelegate: AnyObject {
    func didUpdateText(in cell: QCNotesCardCell)
}

// Delegate for handling title changes in summary cards
protocol QCSummaryCardDelegate: AnyObject {
    func didChangeTitle(text: String)
}

// MARK: - Header Cells

// Header cell for summary section with icon and label
class QCSummarySectionHeaderCell: UITableViewCell {
    @IBOutlet weak var headerIcon: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        // Accessibility
        headerLabel.isAccessibilityElement = true
        headerLabel.accessibilityTraits = .header
    }
}

// Header cell for participants section
class QCParticipantsSummaryHeaderCell: UITableViewCell {
    @IBOutlet weak var participantIcon: UIImageView!
    @IBOutlet weak var participantLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        // Accessibility
        participantLabel.isAccessibilityElement = true
        participantLabel.accessibilityTraits = .header
    }
}

// MARK: - Content Cells

// Card cell displaying conversation summary with editable title field
class QCSummaryCardCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    weak var delegate: QCSummaryCardDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
        titleTextField.delegate = self
        selectionStyle = .none
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Refresh shadow color when switching Light/Dark mode
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            mainCardView.applyCardShadow()
        }
    }
    
    private func setupAppearance() {
        backgroundColor = .clear
        mainCardView.applyCardStyle()
        
        // Accessibility
        titleTextField.accessibilityLabel = "Conversation Title"
        titleTextField.accessibilityHint = "Double tap to edit the title"
    }
    
    // Notifies delegate when conversation title is changed
    @IBAction func titleChanged(_ sender: UITextField) {
        delegate?.didChangeTitle(text: sender.text ?? "")
    }
    
    // Dismiss keyboard on Return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// Card cell displaying individual participant information
class QCParticipantCardCell: UITableViewCell {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
        selectionStyle = .none
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            mainCardView.applyCardShadow()
        }
    }
    
    private func setupAppearance() {
        backgroundColor = .clear
        mainCardView.applyCardStyle()
        
        avatarImageView.layer.cornerRadius = 4
        avatarImageView.clipsToBounds = true
        avatarImageView.tintColor = .systemGray
    }
    
    // Populates the cell with participant data
    func configure(with data: QCParticipantData) {
        detailsLabel.text = data.summary
        
        // Accessibility
        mainCardView.isAccessibilityElement = true
        mainCardView.accessibilityLabel = "Participant: \(data.name). Summary: \(data.summary)"
        
        // Hide sub-elements from VoiceOver since the container reads the full context
        detailsLabel.isAccessibilityElement = false
        avatarImageView.isAccessibilityElement = false
    }
}

// Card cell with expandable text view for conversation notes
class QCNotesCardCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var notesTextView: UITextView!
    
    weak var delegate: QCNotesCardCellDelegate?
    let placeholderText = "Add notes about this conversation..."
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
        setupTextView()
        selectionStyle = .none
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            mainCardView.applyCardShadow()
        }
    }
    
    private func setupAppearance() {
        backgroundColor = .clear
        mainCardView.applyCardStyle()
    }
    
    private func setupTextView() {
        notesTextView.delegate = self
        notesTextView.text = placeholderText
        notesTextView.textColor = .placeholderText // Modern iOS dynamic gray
        notesTextView.font = UIFont.systemFont(ofSize: 15)
        notesTextView.isScrollEnabled = false
        notesTextView.textContainerInset = .zero
        notesTextView.textContainer.lineFragmentPadding = 0
        notesTextView.backgroundColor = .clear
        
        // Accessibility
        notesTextView.accessibilityLabel = "Notes"
    }
    
    // Removes placeholder text when user begins editing
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = nil
            textView.textColor = .label // Adapts to Dark/Light mode
        }
    }
    
    // Restores placeholder if text view is empty after editing
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholderText
            textView.textColor = .placeholderText
        }
    }
    
    // Notifies delegate of text changes for dynamic height adjustment
    func textViewDidChange(_ textView: UITextView) {
        delegate?.didUpdateText(in: self)
    }
}

// MARK: - Styling Extensions

private extension UIView {
    func applyCardStyle() {
        self.layer.cornerRadius = 12
        // Use system background colors for Dark Mode support
        self.backgroundColor = .secondarySystemGroupedBackground
        
        self.applyCardShadow()
        
        // Performance optimization
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
    
    func applyCardShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.05
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 4
    }
}
