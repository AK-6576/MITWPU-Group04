//
//  ActionChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 05/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class BaseChatCell: UICollectionViewCell {
    private var widthConstraint: NSLayoutConstraint?

    func applyBaseBubbleStyle(view: UIView) {
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
    }

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

class OutgoingCell: BaseChatCell {
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyBaseBubbleStyle(view: bubbleView)
        bubbleView.backgroundColor = .systemBlue
        messageLabel.textColor = .white
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
    }
}

class IncomingCell: BaseChatCell {
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
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        setupUI()
    }

    private func setupUI() {
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

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
}

class OutgoingCell2: OutgoingCell {}
class IncomingCell2: IncomingCell {}
