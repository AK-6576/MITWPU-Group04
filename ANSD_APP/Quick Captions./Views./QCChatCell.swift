//
//  ChatCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import UIKit

class QCOutgoingCell: UICollectionViewCell {
    @IBOutlet weak var QCbubbleView: UIView!
    @IBOutlet weak var QCmessageLabel: UILabel!
    
    override func awakeFromNib() {
            super.awakeFromNib()
            
            QCbubbleView.backgroundColor = .systemBlue
            QCmessageLabel.textColor = .white
            QCbubbleView.layer.cornerRadius = 16
            QCbubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
            
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            contentView.widthAnchor.constraint(equalToConstant: screenWidth - 32).isActive = true
        }
        }
    }

class QCIncomingCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 1. Style
        bubbleView.backgroundColor = .systemGray5
        messageLabel.textColor = .black
        
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]
        
        nameLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        nameLabel.addGestureRecognizer(tap)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            contentView.widthAnchor.constraint(equalToConstant: screenWidth - 32).isActive = true
        }
    }
    @objc func handleTap() { onLabelTapped?() }
}
