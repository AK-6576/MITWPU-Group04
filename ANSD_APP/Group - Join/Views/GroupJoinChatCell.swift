//
//  GroupJoinChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// MARK: - Base Class (Action Logic)
class GroupJoinBaseChatCell: UICollectionViewCell {
    private var widthConstraint: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func applyBaseBubbleStyle(view: UIView) {
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
    }

    // Dynamic sizing logic: Pins width to the CollectionView width and calculates height
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
class GroupJoinOutgoingCell: GroupJoinBaseChatCell {
    @IBOutlet weak var GroupJoinBubbleView: UIView!
    @IBOutlet weak var GroupJoinMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyBaseBubbleStyle(view: GroupJoinBubbleView)
        
        GroupJoinBubbleView.backgroundColor = .systemBlue
        GroupJoinMessageLabel.textColor = .white
        GroupJoinMessageLabel.numberOfLines = 0
        
        // Sharp Bottom-Right corner
        GroupJoinBubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
    }
    
    func configure(with message: GroupJoinChatMessage) {
        GroupJoinMessageLabel.text = message.text
    }
}

// MARK: - Incoming Cell (Left Side - Gray)
class GroupJoinIncomingCell: GroupJoinBaseChatCell {
    @IBOutlet weak var GroupJoinNameLabel: UILabel!
    @IBOutlet weak var GroupJoinBubbleView: UIView!
    @IBOutlet weak var GroupJoinMessageLabel: UILabel!
    @IBOutlet weak var GroupJoinProfileImageView: UIImageView!
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyBaseBubbleStyle(view: GroupJoinBubbleView)
        
        GroupJoinBubbleView.backgroundColor = .systemGray5
        GroupJoinMessageLabel.textColor = .black
        GroupJoinMessageLabel.numberOfLines = 0
        
        // Sharp Bottom-Left corner
        GroupJoinBubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        setupUI()
    }
    
    private func setupUI() {
        // Name Label Interaction
        GroupJoinNameLabel.isUserInteractionEnabled = true
        GroupJoinNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        // Profile Image Circle
        if let profileImg = GroupJoinProfileImageView {
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
    func configure(with message: GroupJoinChatMessage) {
        GroupJoinMessageLabel.text = message.text
        GroupJoinNameLabel.text = message.sender
        GroupJoinProfileImageView.image = UIImage(systemName: "person.circle.fill")
    }
}
