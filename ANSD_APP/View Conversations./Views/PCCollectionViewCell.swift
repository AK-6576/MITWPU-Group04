//
//  PCIncomingCell
//  ANSD_APP
//
//  Created by SDC-USER on 16/12/25.
//

import UIKit

class PCIncomingCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var onLabelTapped: (() -> Void)?
    
    // Configures the incoming message bubble with rounded corners and tap gesture
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
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            contentView.widthAnchor.constraint(equalToConstant: screenWidth - 32).isActive = true
        }
    }
    
    // Triggers callback when name label is tapped
    @objc func handleTap() {
        onLabelTapped?()
    }
}

class PCOutgoingCell: UICollectionViewCell {
    @IBOutlet weak var PCbubbleView: UIView!
    @IBOutlet weak var PCmessageLabel: UILabel!
    
    // Configures the outgoing message bubble with blue background and rounded corners
    override func awakeFromNib() {
        super.awakeFromNib()
        PCbubbleView.backgroundColor = .systemBlue
        PCmessageLabel.textColor = .white
        PCbubbleView.layer.cornerRadius = 16
        PCbubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            contentView.widthAnchor.constraint(equalToConstant: screenWidth - 32).isActive = true
        }
    }
}
