//
//  QCChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit

// MARK: - Outgoing Message Cell

// Collection view cell for outgoing messages with blue bubble and right alignment
class QCOutgoingCell: UICollectionViewCell {
    
    @IBOutlet weak var QCbubbleView: UIView!
    @IBOutlet weak var QCmessageLabel: UILabel!
    
    // Constraint to enforce full width for self-sizing calculations
    private lazy var widthConstraint: NSLayoutConstraint = {
        let constraint = contentView.widthAnchor.constraint(equalToConstant: bounds.size.width)
        constraint.isActive = true
        return constraint
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }
    
    private func setupAppearance() {
        QCbubbleView.backgroundColor = .systemBlue
        QCmessageLabel.textColor = .white
        
        QCbubbleView.layer.cornerRadius = 16
        // Rounded corners except bottom-right
        QCbubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
        // Accessibility
        self.isAccessibilityElement = true
        self.accessibilityLabel = "Me: \(QCmessageLabel.text ?? "")"
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        // Update constraint to match the collection view's current available width
        widthConstraint.constant = layoutAttributes.frame.width
        
        // Calculate dynamic height based on the fixed width
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: UIView.layoutFittingExpandedSize.height)
        
        let newSize = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        layoutAttributes.frame.size = newSize
        return layoutAttributes
    }
}

// MARK: - Incoming Message Cell

// Collection view cell for incoming messages with gray bubble and sender name
class QCIncomingCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var onLabelTapped: (() -> Void)?
    
    private lazy var widthConstraint: NSLayoutConstraint = {
        let constraint = contentView.widthAnchor.constraint(equalToConstant: bounds.size.width)
        constraint.isActive = true
        return constraint
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
        setupGestures()
    }
    
    private func setupAppearance() {
        bubbleView.backgroundColor = .systemGray5
        
        // Use .label instead of .black for Dark Mode support
        messageLabel.textColor = .label
        nameLabel.textColor = .secondaryLabel
        
        bubbleView.layer.cornerRadius = 16
        // Rounded corners except bottom-left
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }
    
    private func setupGestures() {
        nameLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        nameLabel.addGestureRecognizer(tap)
    }
    
    // Calculates and returns the preferred size for auto-sizing cells
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        widthConstraint.constant = layoutAttributes.frame.width
        
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: UIView.layoutFittingExpandedSize.height)
        
        let newSize = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        layoutAttributes.frame.size = newSize
        return layoutAttributes
    }
    
    // Handles tap gesture on sender name label to trigger rename action
    @objc private func handleTap() {
        onLabelTapped?()
    }
    
    // Configures Accessibility for VoiceOver
    override var accessibilityLabel: String? {
        get {
            let sender = nameLabel.text ?? "Unknown"
            let message = messageLabel.text ?? ""
            return "\(sender) says: \(message)"
        }
        set { super.accessibilityLabel = newValue }
    }
    
    override var accessibilityHint: String? {
        get { return "Double tap the name to rename this speaker." }
        set { super.accessibilityHint = newValue }
    }
    
    // Custom Actions allow VoiceOver users to rename without finding the small label
    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            let renameAction = UIAccessibilityCustomAction(name: "Rename Speaker", target: self, selector: #selector(handleTap))
            return [renameAction]
        }
        set { super.accessibilityCustomActions = newValue }
    }
}
