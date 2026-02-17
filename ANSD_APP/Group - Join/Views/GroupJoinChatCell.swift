//
//  ChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
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
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            contentView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        }
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
        
        GroupJoinNameLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        GroupJoinNameLabel.addGestureRecognizer(tap)
        
        if let profileImg = GroupJoinProfileImageView {
            profileImg.layer.cornerRadius = profileImg.frame.height / 2
            profileImg.clipsToBounds = true
            profileImg.contentMode = .scaleAspectFill
            profileImg.backgroundColor = .systemGray4
        }
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            contentView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        }
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
    
    @objc func handleTap() {
        onLabelTapped?()
    }
}
