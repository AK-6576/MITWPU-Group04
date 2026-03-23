//
//  ConversationCardCell.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 15/01/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//
import UIKit

// MARK: - Routine Cell (Quick Actions - Top List)
class QuickActionTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var onInfoTapped: (() -> Void)?
    
    private let bottomBorder = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDesign()
    }

    func setupDesign() {
        iconImageView.layer.cornerRadius = 10
        iconImageView.backgroundColor = .systemGray6
        iconImageView.contentMode = .center
        iconImageView.clipsToBounds = true
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        
        self.selectionStyle = .default

        self.backgroundColor = .secondarySystemGroupedBackground
    }

    func configure(with item: RoutineConversation, isLast: Bool) {
        titleLabel.text = item.conversationTopic
        timeLabel.text = item.startTime
        
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        if let image = UIImage(systemName: item.iconName, withConfiguration: config) {
            iconImageView.image = image.withRenderingMode(.alwaysTemplate)
        }
        
        switch item.categoryTitle {
        case "Office":
            iconImageView.tintColor = .systemBlue
        case "Family":
            iconImageView.tintColor = .systemPink
        case "Friends":
            iconImageView.tintColor = .systemGreen
        default:
            iconImageView.tintColor = .systemGray
        }
    }
    
    @objc private func infoButtonTapped() {
        onInfoTapped?()
    }
}

// MARK: - Conversation Card Cell (Detailed List - Bottom Cards)
class ConversationCardCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var cardContainer: UIView!
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var calendarIcon: UIImageView!
    @IBOutlet weak var clockIcon: UIImageView!
    @IBOutlet weak var categoryIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDesign()
    }
    
    func setupDesign() {
        
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.selectionStyle = .none
        
        
        cardContainer.backgroundColor = .secondarySystemGroupedBackground
        cardContainer.layer.cornerRadius = 20
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.masksToBounds = false
        
        cardContainer.layer.borderWidth = 1
        cardContainer.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    func configure(with conversation: Conversation) {
        topicLabel.text = conversation.title
        descriptionLabel.text = conversation.details
        
        dateLabel.text = conversation.formattedDisplayDate
        timeLabel.text = "\(conversation.startTime)"
        
        calendarIcon.image = UIImage(systemName: "calendar")
        calendarIcon.tintColor = .systemGray2
        
        clockIcon.image = UIImage(systemName: "clock")
        clockIcon.tintColor = .systemGray2
        
        categoryLabel.text = conversation.displayCategory
        categoryIcon.image = UIImage(systemName: conversation.categoryIconName)
        categoryIcon.tintColor = conversation.categoryTintColor
        
        categoryLabel.textColor = .secondaryLabel
    }
}
