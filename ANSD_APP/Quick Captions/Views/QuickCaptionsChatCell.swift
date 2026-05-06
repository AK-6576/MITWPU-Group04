//
//  QuickCaptionsChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class QuickCaptionsOutgoingCell: UICollectionViewCell {
    private var widthConstraint: NSLayoutConstraint?
    @IBOutlet weak var QCbubbleView: UIView!
    @IBOutlet weak var QCmessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        QCbubbleView.backgroundColor = .systemBlue
        QCmessageLabel.textColor = .white
        QCbubbleView.layer.cornerRadius = 16
        QCbubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        QCbubbleView.layer.removeAllAnimations()
        QCbubbleView.alpha = 1.0
    }

    func setIdentifying(_ identifying: Bool) {
        QCbubbleView.layer.removeAllAnimations()
        if identifying {
            UIView.animate(withDuration: 0.8, delay: 0,
                           options: [.autoreverse, .repeat, .allowUserInteraction, .curveEaseInOut]) {
                self.QCbubbleView.alpha = 0.6
            }
        } else {
            QCbubbleView.alpha = 1.0
        }
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

class QuickCaptionsIncomingCell: UICollectionViewCell {
    private var widthConstraint: NSLayoutConstraint?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bubbleView.backgroundColor = .systemGray5
        messageLabel.textColor = .label
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        nameLabel.textColor = .secondaryLabel
        nameLabel.font = .systemFont(ofSize: 12, weight: .medium)
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.layer.removeAllAnimations()
        nameLabel.alpha = 1.0
        nameLabel.textColor = .secondaryLabel
    }

    /// Fixed: Prevented double "Identifying" text and improved visibility
    func setIdentifying(_ identifying: Bool, name: String) {
        nameLabel.layer.removeAllAnimations()
        if identifying {
            // Only append (Identifying...) if the name isn't already a placeholder
            if name == "Identifying\u{2026}" || name == "Identifying..." || name == "..." {
                nameLabel.text = "Identifying\u{2026}"
            } else {
                nameLabel.text = "\(name) (Identifying\u{2026})"
            }
            
            UIView.animate(withDuration: 0.8, delay: 0,
                           options: [.autoreverse, .repeat, .allowUserInteraction, .curveEaseInOut]) {
                self.nameLabel.alpha = 0.6
            }
        } else {
            nameLabel.text = name
            nameLabel.alpha = 1.0
        }
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
    
    @objc private func handleTap() {
        onLabelTapped?()
    }
}