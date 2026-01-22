//
//  ConversationCardCells.swift
//  Group_4-ANSD_App
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

    func configure(with item: RoutineConversation) {

        topicLabel.text = item.conversationTopic
        descriptionLabel.text = item.description ?? item.status

        dateLabel.text = item.date ?? "Today"
        timeLabel.text = item.startTime
        

        calendarIcon.image = UIImage(systemName: "calendar")
        calendarIcon.tintColor = .systemGray2
        
        clockIcon.image = UIImage(systemName: "clock")
        clockIcon.tintColor = .systemGray2
        
 
        let categoryString = item.categoryTitle

        let capitalizedCategory = categoryString.prefix(1).uppercased() + categoryString.dropFirst()
        categoryLabel.text = capitalizedCategory
        
        let iconName: String
        let tintColor: UIColor
        
        switch categoryString.lowercased() {
        case "family":
            iconName = "figure.2.and.child.holdinghands"
            tintColor = .systemPurple
        case "friends":
            iconName = "person.3.fill"
            tintColor = .systemGreen
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
        
        categoryLabel.textColor = .secondaryLabel
    }
}
