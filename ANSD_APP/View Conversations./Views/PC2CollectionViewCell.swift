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
    
    // Configures incoming message bubble with rounded corners
    override func awakeFromNib() {
        super.awakeFromNib()
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        bubbleView.backgroundColor = .systemGray5
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        // Modern Auto Layout approach: Calculate height
        let targetSize = CGSize(width: layoutAttributes.size.width, height: UIView.layoutFittingCompressedSize.height)
        
        let size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        var newFrame = layoutAttributes.frame
        newFrame.size.height = size.height.rounded(.up)
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }
}

class PCOutgoing2Cell: UICollectionViewCell {
    @IBOutlet weak var PCmessageLabel: UILabel!
    @IBOutlet var pcBubbleView: UIView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        pcBubbleView.layer.cornerRadius = 16
        pcBubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        pcBubbleView.backgroundColor = .systemBlue
        PCmessageLabel.textColor = .white
    }
    

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        

        let targetSize = CGSize(width: layoutAttributes.size.width, height: UIView.layoutFittingCompressedSize.height)
        
        let size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        var newFrame = layoutAttributes.frame
        newFrame.size.height = size.height.rounded(.up)
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }
}
