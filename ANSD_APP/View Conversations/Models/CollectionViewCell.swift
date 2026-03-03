//
//  CollectionViewCell.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class ViewIncomingCell: UICollectionViewCell {
    
    @IBOutlet var bubbleView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    
    @IBOutlet var editedLabel: UILabel!
    
    // Function - Initializes the incoming cell UI, setting the gray bubble color and rounded corners.
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
    
    // Function - Calculates the preferred size for the cell based on Auto Layout constraints to support dynamic height.
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

class ViewOutgoingCell: UICollectionViewCell {
    @IBOutlet weak var PCmessageLabel: UILabel!
    @IBOutlet var pcBubbleView: UIView!
    @IBOutlet var editedLabel: UILabel!
    
    // Function - Initializes the outgoing cell UI, setting the blue bubble color and rounded corners.
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
