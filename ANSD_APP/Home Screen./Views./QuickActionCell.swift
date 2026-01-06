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
        iconImageView.layer.cornerRadius = 10
        iconImageView.backgroundColor = .systemGray6
        iconImageView.contentMode = .center
        iconImageView.clipsToBounds = true
    }

    func configure(with item: RoutineConversation) {
        titleLabel.text = item.conversationTopic
        subtitleLabel.text = item.startTime
        
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        if let image = UIImage(systemName: item.iconName, withConfiguration: config) {
            iconImageView.image = image.withRenderingMode(.alwaysTemplate)
        }
        
        let category = item.categoryTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("QuickAction Item: \(item.conversationTopic) | Category: '\(category)'")
        
        switch category {
        case "office", "work", "business":
            iconImageView.tintColor = .systemBlue
        case "family", "home", "personal":
            iconImageView.tintColor = .systemPink
        case "friends", "social", "hangout":
            iconImageView.tintColor = .systemGreen
        default:
            iconImageView.tintColor = .systemGray
        }
    }
    
    @IBAction func didTapInfoButton(_ sender: UIButton) {
        onInfoTapped?()
    }
}
