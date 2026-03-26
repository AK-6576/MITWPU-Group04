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
    
    // Custom Programmatic Views
    private let cardContainer = UIView()
    private let customIconContainer = UIView()
    private let customIconImageView = UIImageView()
    
    private let textStackView = UIStackView()
    private let customTitleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private let rightStackView = UIStackView()
    private let customTimeLabel = UILabel()
    private let badgeContainer = UIView()
    private let badgeLabel = UILabel()
    
    private let chevronImageView = UIImageView()
    private let internalBottomSeparator = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDesign()
    }

    func setupDesign() {
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.selectionStyle = .none
        
        // Card Container
        cardContainer.backgroundColor = .secondarySystemGroupedBackground
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardContainer)
        
        // Card Border (Overall boundary)
        cardContainer.layer.borderWidth = 0.5
        cardContainer.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Custom Icon
        customIconContainer.layer.cornerRadius = 10
        customIconContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(customIconContainer)
        
        customIconImageView.contentMode = .scaleAspectFit
        customIconImageView.translatesAutoresizingMaskIntoConstraints = false
        customIconContainer.addSubview(customIconImageView)
        
        // Text Stack
        textStackView.axis = .vertical
        textStackView.spacing = 2
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        
        customTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        customTitleLabel.textColor = .label
        
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        
        textStackView.addArrangedSubview(customTitleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        cardContainer.addSubview(textStackView)
        
        // Chevron
        let chevronConfig = UIImage.SymbolConfiguration(weight: .semibold)
        chevronImageView.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevronImageView.tintColor = .systemGray3
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(chevronImageView)
        
        // Right Stack
        rightStackView.axis = .vertical
        rightStackView.spacing = 6
        rightStackView.alignment = .trailing
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        
        customTimeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        customTimeLabel.textColor = .secondaryLabel
        
        badgeContainer.layer.cornerRadius = 6
        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.addSubview(badgeLabel)
        
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: badgeContainer.topAnchor, constant: 3),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor, constant: -3),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor, constant: 8),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor, constant: -8)
        ])
        
        rightStackView.addArrangedSubview(customTimeLabel)
        rightStackView.addArrangedSubview(badgeContainer)
        cardContainer.addSubview(rightStackView)
        
        // Internal block separator
        internalBottomSeparator.backgroundColor = UIColor.systemGray5
        internalBottomSeparator.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(internalBottomSeparator)
        
        // Main Cell Constraints
        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            cardContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 76),
            
            customIconContainer.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 16),
            customIconContainer.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            customIconContainer.widthAnchor.constraint(equalToConstant: 44),
            customIconContainer.heightAnchor.constraint(equalToConstant: 44),
            
            customIconImageView.centerXAnchor.constraint(equalTo: customIconContainer.centerXAnchor),
            customIconImageView.centerYAnchor.constraint(equalTo: customIconContainer.centerYAnchor),
            customIconImageView.widthAnchor.constraint(equalToConstant: 22),
            customIconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            textStackView.leadingAnchor.constraint(equalTo: customIconContainer.trailingAnchor, constant: 15),
            textStackView.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 10),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14),
            
            rightStackView.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            rightStackView.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            rightStackView.leadingAnchor.constraint(greaterThanOrEqualTo: textStackView.trailingAnchor, constant: 8),
            
            internalBottomSeparator.leadingAnchor.constraint(equalTo: textStackView.leadingAnchor),
            internalBottomSeparator.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            internalBottomSeparator.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),
            internalBottomSeparator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func applyCornerRounding(isFirst: Bool, isLast: Bool) {
        var maskedCorners: CACornerMask = []
        if isFirst {
            maskedCorners.insert(.layerMinXMinYCorner)
            maskedCorners.insert(.layerMaxXMinYCorner)
        }
        if isLast {
            maskedCorners.insert(.layerMinXMaxYCorner)
            maskedCorners.insert(.layerMaxXMaxYCorner)
        }
        
        cardContainer.layer.cornerRadius = (isFirst || isLast) ? 16 : 0
        cardContainer.layer.maskedCorners = maskedCorners
        cardContainer.clipsToBounds = true
        
        internalBottomSeparator.isHidden = isLast
    }

    func configure(with item: RoutineConversation?, isFirst: Bool, isLast: Bool, isAddRow: Bool) {
        applyCornerRounding(isFirst: isFirst, isLast: isLast)
        
        let config = UIImage.SymbolConfiguration(weight: .semibold)
        
        if isAddRow {
            customTitleLabel.text = "Add Quick Action"
            customTitleLabel.textColor = .systemBlue
            subtitleLabel.isHidden = true
            rightStackView.isHidden = true
            
            customIconContainer.backgroundColor = UIColor.secondarySystemFill
            if let image = UIImage(systemName: "plus", withConfiguration: config) {
                customIconImageView.image = image.withRenderingMode(.alwaysTemplate)
            }
            customIconImageView.tintColor = .secondaryLabel
        } else if let item = item {
            customTitleLabel.text = item.conversationTopic
            customTitleLabel.textColor = .label
            subtitleLabel.isHidden = false
            rightStackView.isHidden = false
            
            let paxCount = max(1, item.participantNames.count)
            let paxText = paxCount == 1 ? "1 participant" : "\(paxCount) participants"
            subtitleLabel.text = "\(item.categoryTitle) • \(paxText)"
            
            customTimeLabel.text = item.startTime
            
            // Determine Upcoming vs Scheduled based on time
            let df = DateFormatter()
            df.dateFormat = "h:mm a"
            df.locale = Locale(identifier: "en_US_POSIX")
            var badgeText = "Scheduled"
            
            if let targetDate = df.date(from: item.startTime) {
                let now = Date()
                let cal = Calendar.current
                var tComps = cal.dateComponents([.hour, .minute], from: targetDate)
                let nComps = cal.dateComponents([.year, .month, .day], from: now)
                tComps.year = nComps.year
                tComps.month = nComps.month
                tComps.day = nComps.day
                
                if let combinedTarget = cal.date(from: tComps) {
                    let diff = combinedTarget.timeIntervalSince(now)
                    if diff > 0 && diff <= 3600 * 4 {
                        badgeText = "Upcoming"
                    }
                }
            }
            badgeLabel.text = badgeText
            
            if let image = UIImage(systemName: item.iconName, withConfiguration: config) {
                customIconImageView.image = image.withRenderingMode(.alwaysTemplate)
            }
            
            var tintColor: UIColor = .systemGray
            switch item.categoryTitle {
            case "Office": tintColor = .systemBlue
            case "Family": tintColor = .systemGreen
            case "Friends": tintColor = .systemOrange
            default: tintColor = .systemGray
            }
            
            // Add custom distinction color for 'Upcoming' status
            if badgeText == "Upcoming" {
                badgeContainer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
                badgeLabel.textColor = .systemRed
            } else {
                badgeContainer.backgroundColor = tintColor.withAlphaComponent(0.15)
                badgeLabel.textColor = tintColor
            }
            
            customIconContainer.backgroundColor = tintColor.withAlphaComponent(0.15)
            customIconImageView.tintColor = tintColor
        }
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
