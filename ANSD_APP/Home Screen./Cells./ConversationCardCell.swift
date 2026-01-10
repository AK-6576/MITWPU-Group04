//
//  ConversationCells.swift
//  Group_4-ANSD_App
//

import UIKit

// MARK: - Routine Cell (Quick Actions - Top List)
class RoutineTableViewCell: UITableViewCell {
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
        // ensure background is white/system so it looks like a continuous list
        self.backgroundColor = .secondarySystemGroupedBackground
    }
    
    func setupCustomSeparator() {
        bottomBorder.backgroundColor = .systemGray5
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomBorder)
        
        NSLayoutConstraint.activate([
            bottomBorder.heightAnchor.constraint(equalToConstant: 1),
            bottomBorder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomBorder.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), // Align line with text
            bottomBorder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    // Added 'isLast' parameter to hide separator on the final item
    func configure(with item: RoutineConversation, isLast: Bool) {
        titleLabel.text = item.conversationTopic
        timeLabel.text = item.startTime
        bottomBorder.isHidden = isLast
        
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
    
    // Separate labels as requested
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
        // Transparent background for the cell so the TableView gray shows through
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.selectionStyle = .none
        
        // Card Styling
        cardContainer.backgroundColor = .secondarySystemGroupedBackground // White in light mode, Dark Gray in dark mode
        cardContainer.layer.cornerRadius = 20
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.masksToBounds = false
        
        // Border
        cardContainer.layer.borderWidth = 1
        cardContainer.layer.borderColor = UIColor.systemGray5.cgColor
        
        // Shadow
        cardContainer.layer.shadowColor = UIColor.black.cgColor
        cardContainer.layer.shadowOpacity = 0.08
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardContainer.layer.shadowRadius = 6
    }

    func configure(with item: RoutineConversation) {
        // 1. Basic Text
        topicLabel.text = item.conversationTopic
        descriptionLabel.text = item.description ?? item.status
        
        // 2. Metadata Labels
        dateLabel.text = item.date ?? "Today"
        timeLabel.text = item.startTime
        
        // 3. Static Icons setup
        calendarIcon.image = UIImage(systemName: "calendar")
        calendarIcon.tintColor = .systemGray2
        
        clockIcon.image = UIImage(systemName: "clock")
        clockIcon.tintColor = .systemGray2
        
        // 4. Category Styling Logic
        let categoryString = item.categoryTitle
        // Capitalize first letter
        let capitalizedCategory = categoryString.prefix(1).uppercased() + categoryString.dropFirst()
        categoryLabel.text = capitalizedCategory
        
        let iconName: String
        let tintColor: UIColor
        
        switch categoryString.lowercased() {
        case "family":
            iconName = "figure.2.and.child.holdinghands"
            tintColor = .systemPink
        case "friends":
            iconName = "person.2.fill"
            tintColor = .systemOrange
        case "office", "work":
            iconName = "briefcase.fill"
            tintColor = .systemBlue
        case "medical", "health":
            iconName = "cross.case.fill"
            tintColor = .systemGreen
        default:
            iconName = "folder.fill"
            tintColor = .systemGray
        }
        
        categoryIcon.image = UIImage(systemName: iconName)
        categoryIcon.tintColor = tintColor
        
        // Optional: Color the label to match the icon
        categoryLabel.textColor = .secondaryLabel
    }
}
