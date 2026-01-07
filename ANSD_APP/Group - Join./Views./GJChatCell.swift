//
//  ChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit

class GJOutgoingCell: UICollectionViewCell {
    @IBOutlet weak var GJbubbleView: UIView!
    @IBOutlet weak var GJmessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        GJbubbleView.backgroundColor = .systemBlue
        GJmessageLabel.textColor = .white
        GJbubbleView.layer.cornerRadius = 16
        GJbubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
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

class GJIncomingCell: UICollectionViewCell {
    @IBOutlet weak var GJnameLabel: UILabel!
    @IBOutlet weak var GJbubbleView: UIView!
    @IBOutlet weak var GJmessageLabel: UILabel!
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        GJbubbleView.backgroundColor = .systemGray5
        GJmessageLabel.textColor = .black
        GJbubbleView.layer.cornerRadius = 16
        GJbubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        GJnameLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        GJnameLabel.addGestureRecognizer(tap)
        
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
