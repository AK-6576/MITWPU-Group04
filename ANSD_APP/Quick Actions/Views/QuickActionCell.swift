//
//  QuickActionCell.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 16/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
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
        iconImageView.layer.cornerRadius = 10
        iconImageView.backgroundColor = .systemGray6
        iconImageView.contentMode = .center
        iconImageView.clipsToBounds = true
    }

    func configure(with item: RoutineConversation) {
        titleLabel.text = item.conversationTopic
        subtitleLabel.text = item.startTime
        
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        let iconName = item.iconName
        
        if let image = UIImage(systemName: iconName, withConfiguration: config) {
            iconImageView.image = image.withRenderingMode(.alwaysTemplate)
        }

        let category = item.categoryTitle
        let color = getColorForCategory(category)

        iconImageView.tintColor = color
    }
}
