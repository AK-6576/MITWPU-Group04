//
//  GroupJoinChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class GroupJoinOutgoingCell: UICollectionViewCell {
    @IBOutlet weak var GroupJoinBubbleView: UIView!
    @IBOutlet weak var GroupJoinMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        GroupJoinBubbleView.backgroundColor = .systemBlue
        GroupJoinMessageLabel.textColor = .white
        GroupJoinBubbleView.layer.cornerRadius = 16
        GroupJoinBubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
        GroupJoinMessageLabel.numberOfLines = 0
        
        // Pins contentView width to the screen width so Auto Layout can correctly compute self-sizing cell height.
        contentView.translatesAutoresizingMaskIntoConstraints = false
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
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

    func configure(with message: GroupJoinChatMessage) {
        GroupJoinMessageLabel.text = message.text
    }
}

class GroupJoinIncomingCell: UICollectionViewCell {
    @IBOutlet weak var GroupJoinNameLabel: UILabel!
    @IBOutlet weak var GroupJoinBubbleView: UIView!
    @IBOutlet weak var GroupJoinMessageLabel: UILabel!
    @IBOutlet weak var GroupJoinProfileImageView: UIImageView!
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        GroupJoinBubbleView.backgroundColor = .systemGray5
        GroupJoinMessageLabel.textColor = .black
        GroupJoinBubbleView.layer.cornerRadius = 16
        GroupJoinBubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        GroupJoinMessageLabel.numberOfLines = 0
        GroupJoinNameLabel.isUserInteractionEnabled = true
        GroupJoinNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        GroupJoinProfileImageView?.layer.cornerRadius = (GroupJoinProfileImageView?.frame.height ?? 30) / 2
        GroupJoinProfileImageView?.clipsToBounds = true
        
        // Optimize constraints for auto-sizing
        contentView.translatesAutoresizingMaskIntoConstraints = false
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            // Width constraint helps Auto Layout calculate height correctly
            contentView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        }
    }
    
    @objc func handleTap() { onLabelTapped?() }
    
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
    
    func configure(with message: GroupJoinChatMessage) {
        GroupJoinMessageLabel.text = message.text
        GroupJoinNameLabel.text = message.sender
        GroupJoinProfileImageView.image = UIImage(systemName: "person.circle.fill")
    }
}
