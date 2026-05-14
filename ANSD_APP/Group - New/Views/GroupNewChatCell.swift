//
//  GroupNewChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// MARK: - Base Class (Logic from ActionChatCell)
class GroupNewBaseChatCell: UICollectionViewCell {
    private var widthConstraint: NSLayoutConstraint?

    func applyBaseBubbleStyle(view: UIView) {
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
    }

    // Dynamic sizing logic copied from ActionChatCell
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if widthConstraint == nil {
            widthConstraint = contentView.widthAnchor.constraint(equalToConstant: layoutAttributes.frame.width)
            widthConstraint?.isActive = true
        } else {
            widthConstraint?.constant = layoutAttributes.frame.width
        }

        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        let size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

        var newFrame = layoutAttributes.frame
        newFrame.size.height = ceil(size.height)
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }
}

// MARK: - Outgoing Cell (Right Side - Blue)
class GroupNewOutgoingCell: GroupNewBaseChatCell {
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyBaseBubbleStyle(view: bubbleView)

        bubbleView.backgroundColor = .systemBlue
        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0

        // Masked Corners: Top-Left, Top-Right, Bottom-Left rounded. Bottom-Right sharp.
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
    }

    func configure(with message: GroupNewChatMessage) {
        messageLabel.text = message.text
    }
}

// MARK: - Incoming Cell (Left Side - Gray)
class GroupNewIncomingCell: GroupNewBaseChatCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!

    var onLabelTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        applyBaseBubbleStyle(view: bubbleView)

        bubbleView.backgroundColor = .systemGray5
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0

        // Masked Corners: Top-Left, Top-Right, Bottom-Right rounded. Bottom-Left sharp.
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        setupUI()
    }

    private func setupUI() {
        // Tap Setup
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        // Profile Image Setup
        if let profileImg = profileImageView {
            profileImg.layer.cornerRadius = profileImg.frame.height / 2
            profileImg.clipsToBounds = true
            profileImg.contentMode = .scaleAspectFill
            profileImg.backgroundColor = .systemGray4
        }
    }

    @objc private func handleTap() {
        onLabelTapped?()
    }

    // MARK: - Configuration
    func configure(with message: GroupNewChatMessage) {
        messageLabel.text = message.text
        nameLabel.text = message.sender
    }
}
