//
//  GroupJoinChatCell.swift
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
        
        GroupJoinMessageLabel.numberOfLines = 0
        
        // FIX: Removed translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configure(with message: GroupJoinChatMessage) {
        GroupJoinMessageLabel.text = message.text
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
        
        GroupJoinMessageLabel.numberOfLines = 0
        GroupJoinNameLabel.isUserInteractionEnabled = true
        GroupJoinNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        GroupJoinProfileImageView?.layer.cornerRadius = (GroupJoinProfileImageView?.frame.height ?? 30) / 2
        GroupJoinProfileImageView?.clipsToBounds = true
    }
    
    @objc func handleTap() { onLabelTapped?() }
    
    func configure(with message: GroupJoinChatMessage) {
        GroupJoinMessageLabel.text = message.text
        GroupJoinNameLabel.text = message.sender
        GroupJoinProfileImageView.image = UIImage(systemName: "person.circle.fill")
    }
}
