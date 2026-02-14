//
//  QuickCaptionsChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit

// MARK: - Outgoing Cell (Blue / User)
class QuickCaptionsOutgoingCell: UICollectionViewCell {
    @IBOutlet weak var QCbubbleView: UIView!
    @IBOutlet weak var QCmessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        QCbubbleView.backgroundColor = .systemBlue
        QCmessageLabel.textColor = .white
        QCbubbleView.layer.cornerRadius = 16
        QCbubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
        // Ensure width constraints match screen width
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            contentView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        }
    }
    
    // Auto-sizing magic
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var newFrame = layoutAttributes.frame
        newFrame.size.height = ceil(size.height)
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }
    
    func configure(with msg: QuickCaptionsChat) {
        QCmessageLabel.text = msg.text
    }
}

// MARK: - Incoming Cell (Gray / Others)
class QuickCaptionsIncomingCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bubbleView.backgroundColor = .systemGray5
        messageLabel.textColor = .black
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            contentView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        }
        
        // Tap Gesture for renaming
        nameLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        nameLabel.addGestureRecognizer(tap)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var newFrame = layoutAttributes.frame
        newFrame.size.height = ceil(size.height)
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }
    
    func configure(with msg: QuickCaptionsChat) {
        nameLabel.text = msg.sender
        messageLabel.text = msg.text
    }
    
    @objc private func handleTap() {
        onLabelTapped?()
    }
}
