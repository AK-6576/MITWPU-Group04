//
//  PC2CollectionViewCell.swift
//  ANSD_APP
//
//  Created by SDC-USER on 06/01/26.
//

import UIKit

class PC2IncomingViewCell: UICollectionViewCell {
    
    @IBOutlet var bubbleView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    
    // Configures incoming message bubble with rounded corners and dynamic width
    override func awakeFromNib() {
        super.awakeFromNib()
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        bubbleView.backgroundColor = .systemGray5
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
             let screenWidth = windowScene.screen.bounds.width
             contentView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        }
    }
    
    // Calculates and returns preferred layout attributes for dynamic cell height
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

class PCOutgoing2Cell: UICollectionViewCell {
    @IBOutlet weak var PCmessageLabel: UILabel!
    @IBOutlet var pcBubbleView: UIView!
    
    // Configures outgoing message bubble with blue background and rounded corners
    override func awakeFromNib() {
        super.awakeFromNib()
        pcBubbleView.layer.cornerRadius = 16
        pcBubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        pcBubbleView.backgroundColor = .systemBlue
        PCmessageLabel.textColor = .white
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
             let screenWidth = windowScene.screen.bounds.width
             contentView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
        }
    }
    
    // Calculates and returns preferred layout attributes for dynamic cell height
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
