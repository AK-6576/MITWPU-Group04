//
//  QuickActionCell.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 16/12/25.
//

import UIKit

class QuickActionCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    // MARK: - Actions Closure
    // This allows the HomeViewController to know when the button is clicked
    var onInfoTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Optional: Make the image look like a rounded button
        iconImageView.layer.cornerRadius = 10
        iconImageView.backgroundColor = .systemGray6
        iconImageView.contentMode = .center // Keeps the symbol centered inside the gray box
    }

    func configure(with item: RoutineConversation) {
        // 1. Set Text
        titleLabel.text = item.conversationTopic
        subtitleLabel.text = item.timeRange
        
        // 2. Set Image (SF Symbol)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iconImageView.image = UIImage(systemName: item.iconName, withConfiguration: config)
        
        // 3. Style the Image View
        iconImageView.contentMode = .center
        iconImageView.tintColor = .systemBlue
        iconImageView.backgroundColor = .systemGray6
        iconImageView.layer.cornerRadius = 10
    }
    
    // MARK: - IBAction (The missing link causing the crash)
    // Connect this to the (i) button in your Storyboard!
    @IBAction func didTapInfoButton(_ sender: UIButton) {
        // Trigger the closure so the View Controller can show the popup
        onInfoTapped?()
    }
}
