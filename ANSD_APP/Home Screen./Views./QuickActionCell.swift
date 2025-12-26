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
    // This allows the Controller to know when the (i) button is clicked
    var onInfoTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDesign()
    }
    
    func setupDesign() {
        // Uniform Design
        iconImageView.layer.cornerRadius = 10
        iconImageView.backgroundColor = .systemGray6
        iconImageView.contentMode = .center
        iconImageView.clipsToBounds = true
    }

    func configure(with item: RoutineConversation) {
        // 1. Set Text
        titleLabel.text = item.conversationTopic
        subtitleLabel.text = item.timeRange
        
        // 2. Set Image with Template Mode
        // .alwaysTemplate is required for the tintColor to take effect
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        if let image = UIImage(systemName: item.iconName, withConfiguration: config) {
            iconImageView.image = image.withRenderingMode(.alwaysTemplate)
        }
        
        // 3. Robust Color Logic
        // Clean the string (lowercase + trim spaces) to ensure matching works
        let category = item.categoryTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Debugging: Check console to see what category is detected
        print("QuickAction Item: \(item.conversationTopic) | Category: '\(category)'")
        
        switch category {
        case "office", "work", "business":
            iconImageView.tintColor = .systemBlue
            
        case "family", "home", "personal":
            iconImageView.tintColor = .systemPink
            
        case "friends", "social", "hangout":
            iconImageView.tintColor = .systemGreen
            
        default:
            // Use Dark Gray so icons are visible if the name doesn't match
            iconImageView.tintColor = .systemGray
        }
    }
    
    // MARK: - IBAction
    // Connect this to the (i) button in Storyboard
    @IBAction func didTapInfoButton(_ sender: UIButton) {
        onInfoTapped?()
    }
}
