//
//  ConversationCardCell.swift
//  Group_4-ANSD_App
//
//  Created by Daiwiik Harihar on 10/12/25.
//

import UIKit

class RoutineTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton?
    
    // Callback invoked when the (i) button is tapped
    var onInfoTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDesign()
        
        // Wire up info button if connected in Interface Builder
        infoButton?.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
    }

    func setupDesign() {
        // 1. Icon Styling
        iconImageView.contentMode = .scaleAspectFit
        // This is required for the constraints above to look right
        iconImageView.layer.cornerRadius = 10
        iconImageView.clipsToBounds = true
        iconImageView.tintColor = .systemBlue // Matches your screenshot
        
        // 2. Text Styling
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label // Black
        
        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = .secondaryLabel // Gray
        
        // 3. Selection Style
        self.selectionStyle = .default // Keeps the gray tap effect
    }

    func configure(with item: RoutineConversation) {
        titleLabel.text = item.conversationTopic
        timeLabel.text = item.timeRange
        
        // Image Configuration
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        iconImageView.image = UIImage(systemName: item.iconName, withConfiguration: config)
    }
    
    @objc private func infoButtonTapped() {
        onInfoTapped?()
    }
}
class ConversationCardCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var cardContainer: UIView!
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var metadataLabel: UILabel! // Connect your single bottom label here

    override func awakeFromNib() {
        super.awakeFromNib()
        setupDesign()
    }

    func setupDesign() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        
        // Card Shadow & Radius
        cardContainer.layer.cornerRadius = 14
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.shadowColor = UIColor.black.cgColor
        cardContainer.layer.shadowOpacity = 0.08
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardContainer.layer.shadowRadius = 4
    }

    func configure(with item: RoutineConversation) {
        // 1. Topic
        topicLabel.text = item.conversationTopic
        
        // 2. Description
        descriptionLabel.text = item.description ?? item.status

        // --- Setup Icons ---
        let calendar = NSTextAttachment()
        calendar.image = UIImage(systemName: "calendar")?.withTintColor(.systemGray3)
        calendar.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        
        let clock = NSTextAttachment()
        clock.image = UIImage(systemName: "clock")?.withTintColor(.systemGray3)
        clock.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        
        let tag = NSTextAttachment()
        tag.image = UIImage(systemName: "tag.fill")?.withTintColor(.systemGray3)
        tag.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)

        // --- Setup Divider ---
        // A light gray vertical bar with spaces around it
        let divider = NSAttributedString(
            string: " | ",
            attributes: [.foregroundColor: UIColor.tertiaryLabel]
        )

        // --- Construct the Metadata String ---
        let fullString = NSMutableAttributedString()
        
        // Part A: Date (Only if it exists)
        if let dateText = item.date {
            fullString.append(NSAttributedString(attachment: calendar))
            fullString.append(NSAttributedString(string: " \(dateText)"))
            
            // Add divider after Date
            fullString.append(divider)
        }
        
        // Part B: Time
        fullString.append(NSAttributedString(attachment: clock))
        fullString.append(NSAttributedString(string: " \(item.timeRange)"))
        
        // Add divider after Time
        fullString.append(divider)
        
        // Part C: Category
        fullString.append(NSAttributedString(attachment: tag))
        fullString.append(NSAttributedString(string: " \(item.categoryTitle)"))

        // Apply to label
        metadataLabel.attributedText = fullString
        metadataLabel.textColor = .secondaryLabel
    }
}

