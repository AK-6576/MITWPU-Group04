//
//  ChatCell.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 25/11/25.
//

import UIKit

class OutgoingCell1: UICollectionViewCell {
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    private var widthConstraint: NSLayoutConstraint?
    
    override func awakeFromNib() {
            super.awakeFromNib()
            
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            bubbleView.layer.cornerRadius = 16
            bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
            
        // width constraint is configured in layoutSubviews()
        }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Derive width from the current window's screen to avoid UIScreen.main deprecation
        let screenWidth: CGFloat
        if let screen = window?.windowScene?.screen {
            screenWidth = screen.bounds.width
        } else if let w = window {
            screenWidth = w.bounds.width
        } else {
            screenWidth = contentView.superview?.bounds.width ?? contentView.bounds.width
        }
        let targetWidth = max(0, screenWidth - 32)
        if let widthConstraint = widthConstraint {
            widthConstraint.constant = targetWidth
        } else {
            let c = contentView.widthAnchor.constraint(equalToConstant: targetWidth)
            c.isActive = true
            widthConstraint = c
        }
    }
}

class IncomingCell1: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    private var widthConstraint: NSLayoutConstraint?
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
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
        
        // width constraint is configured in layoutSubviews()
    }
    @objc func handleTap() { onLabelTapped?() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Derive width from the current window's screen to avoid UIScreen.main deprecation
        let screenWidth: CGFloat
        if let screen = window?.windowScene?.screen {
            screenWidth = screen.bounds.width
        } else if let w = window {
            screenWidth = w.bounds.width
        } else {
            screenWidth = contentView.superview?.bounds.width ?? contentView.bounds.width
        }
        let targetWidth = max(0, screenWidth - 32)
        if let widthConstraint = widthConstraint {
            widthConstraint.constant = targetWidth
        } else {
            let c = contentView.widthAnchor.constraint(equalToConstant: targetWidth)
            c.isActive = true
            widthConstraint = c
        }
    }
}
