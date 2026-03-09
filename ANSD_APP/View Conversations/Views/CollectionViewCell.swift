//
//  CollectionViewCell.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class ViewIncomingCell: UICollectionViewCell {
    private var widthConstraint: NSLayoutConstraint?
    @IBOutlet var bubbleView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var editedLabel: UILabel!
    
override func awakeFromNib() {
        super.awakeFromNib()
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        bubbleView.backgroundColor = .systemGray5
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

class ViewOutgoingCell: UICollectionViewCell {
    private var widthConstraint: NSLayoutConstraint?
    @IBOutlet weak var PCmessageLabel: UILabel!
    @IBOutlet var pcBubbleView: UIView!
    @IBOutlet var editedLabel: UILabel!
    
override func awakeFromNib() {
        super.awakeFromNib()
        pcBubbleView.layer.cornerRadius = 16
        pcBubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        pcBubbleView.backgroundColor = .systemBlue
        PCmessageLabel.textColor = .white
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