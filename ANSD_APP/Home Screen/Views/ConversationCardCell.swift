//
//  ConversationCardCell.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 15/01/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//
import UIKit

// MARK: - Routine Cell (Quick Actions - Home Screen)
class QuickActionTableViewCell: UITableViewCell {

    // MARK: - Storyboard Outlets
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!   // repurposed as "Category · N participants"

    var onInfoTapped: (() -> Void)?

    // MARK: - Programmatic Right-side Views
    private let timeLabelRight = UILabel()
    private let todayBadgeContainer = UIView()
    private let todayBadgeLabel = UILabel()
    private var rightViewsAdded = false

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupBaseDesign()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !rightViewsAdded {
            setupRightSideViews()
            rightViewsAdded = true
        }
    }

    // MARK: - Setup

    private func setupBaseDesign() {
        // Icon
        iconImageView.layer.cornerRadius = 12
        iconImageView.clipsToBounds = true
        iconImageView.contentMode = .center

        // Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        // Subtitle (category · participants) – reusing timeLabel outlet
        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = .secondaryLabel

        self.selectionStyle = .default
        self.backgroundColor = .secondarySystemGroupedBackground
    }

    private func setupRightSideViews() {
        // Right-side time label
        timeLabelRight.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        timeLabelRight.textColor = .secondaryLabel
        timeLabelRight.textAlignment = .right
        timeLabelRight.translatesAutoresizingMaskIntoConstraints = false

        // "Today" badge container
        todayBadgeContainer.layer.cornerRadius = 8
        todayBadgeContainer.clipsToBounds = true
        todayBadgeContainer.translatesAutoresizingMaskIntoConstraints = false

        // "Today" badge label
        todayBadgeLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        todayBadgeLabel.textColor = .white
        todayBadgeLabel.textAlignment = .center
        todayBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        todayBadgeContainer.addSubview(todayBadgeLabel)

        contentView.addSubview(timeLabelRight)
        contentView.addSubview(todayBadgeContainer)

        NSLayoutConstraint.activate([
            // Badge label padding inside container
            todayBadgeLabel.topAnchor.constraint(equalTo: todayBadgeContainer.topAnchor, constant: 3),
            todayBadgeLabel.bottomAnchor.constraint(equalTo: todayBadgeContainer.bottomAnchor, constant: -3),
            todayBadgeLabel.leadingAnchor.constraint(equalTo: todayBadgeContainer.leadingAnchor, constant: 8),
            todayBadgeLabel.trailingAnchor.constraint(equalTo: todayBadgeContainer.trailingAnchor, constant: -8),

            // Time label — top-right of cell
            timeLabelRight.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            timeLabelRight.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),

            // Badge — below time label
            todayBadgeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            todayBadgeContainer.topAnchor.constraint(equalTo: timeLabelRight.bottomAnchor, constant: 5),
        ])

        // Restrict title and subtitle labels to not overlap right column
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Disable any existing trailing constraints on title/subtitle originating from the cell
        for c in self.constraints + contentView.constraints {
            let isTitle = (c.firstItem as? UIView == titleLabel || c.secondItem as? UIView == titleLabel)
            let isSubtitle = (c.firstItem as? UIView == timeLabel || c.secondItem as? UIView == timeLabel)
            if (isTitle || isSubtitle) && (c.firstAttribute == .trailing || c.secondAttribute == .trailing) {
                c.isActive = false
            }
        }

        NSLayoutConstraint.activate([
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabelRight.leadingAnchor, constant: -8),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabelRight.leadingAnchor, constant: -8),
        ])
    }

    // MARK: - Configure

    func configure(with item: RoutineConversation, isLast: Bool) {
        // Title
        titleLabel.text = item.conversationTopic

        // Subtitle: "Category · N participants"
        let count = item.participantNames.count
        let pStr = count == 1 ? "1 participant" : "\(count) participants"
        timeLabel.text = "\(item.categoryTitle) · \(pStr)"

        // Icon
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        if let image = UIImage(systemName: item.iconName, withConfiguration: config) {
            iconImageView.image = image.withRenderingMode(.alwaysTemplate)
        }

        // Category colour
        let color = getColorForCategory(item.categoryTitle)
        iconImageView.tintColor = color
        iconImageView.backgroundColor = color.withAlphaComponent(0.15)
        iconImageView.layer.cornerRadius = 12

        // Right-side time
        timeLabelRight.text = item.startTime

        // Today badge
        todayBadgeLabel.text = "Today"
        todayBadgeContainer.backgroundColor = color
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
