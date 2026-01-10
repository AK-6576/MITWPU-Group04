//
//  QuickActionCell.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 16/12/25.
//

import UIKit

class QuickActionCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    var onInfoTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDesign()
    }
    
    func setupDesign() {
        // Design: Gray square background with rounded corners
        iconImageView.layer.cornerRadius = 10
        iconImageView.backgroundColor = .systemGray6
        iconImageView.contentMode = .center
        iconImageView.clipsToBounds = true
    }

    func configure(with item: RoutineConversation) {
        // 1. Text Configuration
        titleLabel.text = item.conversationTopic
        subtitleLabel.text = item.startTime
        
        // 2. Icon Configuration
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        let iconName = item.iconName // Fallback to 'tag' if nil
        
        if let image = UIImage(systemName: iconName, withConfiguration: config) {
            // .alwaysTemplate is CRITICAL. It tells iOS "Ignore the image's original color, use tintColor instead"
            iconImageView.image = image.withRenderingMode(.alwaysTemplate)
        }
        
        // 3. Color Configuration (The Fix)
        // We use the shared helper to get the exact color for this category
        let category = item.categoryTitle
        let color = getColorForCategory(category)
        
        // Apply the color to the icon
        iconImageView.tintColor = color
    }
}
