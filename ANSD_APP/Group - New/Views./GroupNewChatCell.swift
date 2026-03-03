//
//  GroupNewChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// MARK: - Outgoing Cell (Right Side - Blue)
class GroupNewOutgoingCell: UICollectionViewCell {
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyle()
    }
    
    private func setupStyle() {
        // Style Setup
        bubbleView.backgroundColor = .systemBlue
        messageLabel.textColor = .white
        bubbleView.layer.cornerRadius = 16
        // Top-Left, Top-Right, Bottom-Left rounded. Bottom-Right sharp.
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
        // CRITICAL: Allow text to wrap
        messageLabel.numberOfLines = 0
        
        // Optimize constraints for auto-sizing
        contentView.translatesAutoresizingMaskIntoConstraints = false
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            // Width constraint helps Auto Layout calculate height correctly
            contentView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: UIView.layoutFittingExpandedSize.height)
        let autoLayoutSize = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        let newAttributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
        newAttributes.frame.size = autoLayoutSize
        return newAttributes
    }
    
    // MARK: - Configuration
    func configure(with message: GroupNewChatMessage) {
        messageLabel.text = message.text
    }
}

// MARK: - Incoming Cell (Left Side - Gray)
class GroupNewIncomingCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyle()
    }
    
    private func setupStyle() {
        // Style Setup
        bubbleView.backgroundColor = .systemGray5
        messageLabel.textColor = .black
        bubbleView.layer.cornerRadius = 16
        // Top-Left, Top-Right, Bottom-Right rounded. Bottom-Left sharp.
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        // CRITICAL: Allow text to wrap
        messageLabel.numberOfLines = 0
        
        // Tap Setup
        nameLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        nameLabel.addGestureRecognizer(tap)
        
        // Profile Image Setup
        if let profileImg = profileImageView {
            profileImg.layer.cornerRadius = profileImg.frame.height / 2
            profileImg.clipsToBounds = true
            profileImg.contentMode = .scaleAspectFill
            profileImg.backgroundColor = .systemGray4
        }
        
        // Optimize constraints for auto-sizing
        contentView.translatesAutoresizingMaskIntoConstraints = false
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            // Width constraint helps Auto Layout calculate height correctly
            contentView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: UIView.layoutFittingExpandedSize.height)
        let autoLayoutSize = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        let newAttributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
        newAttributes.frame.size = autoLayoutSize
        return newAttributes
    }
    
    @objc func handleTap() {
        onLabelTapped?()
    }
    
    // MARK: - Configuration
    func configure(with message: GroupNewChatMessage) {
        messageLabel.text = message.text
        nameLabel.text = message.sender
    }
}
