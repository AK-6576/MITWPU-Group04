//
//  ConversationCollectionViewCell.swift
//  Group_4-ANSD_App
//
//  Created by Omkar Varpe on 26/11/25.
//

import UIKit

class ConversationCollectionViewCell: UICollectionViewCell {
    
   
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var calendarIcon: UIImageView!
    @IBOutlet weak var clockIcon: UIImageView!
    @IBOutlet weak var categoryIcon: UIImageView!
    
    private var categoryAccessibilityName: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()

        // MARK: - Prominent Card Styling
        self.backgroundColor = .secondarySystemGroupedBackground
        self.layer.cornerRadius = 20
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.15
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 8
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
   func configure(with conversation: Conversation) {
        self.titleLabel.text = conversation.title
        self.descriptionLabel.text = conversation.description
        
        let categoryString = conversation.category
       let capitalizedCategory = categoryString!.prefix(1).uppercased() + categoryString!.dropFirst()
        self.categoryLabel.text = capitalizedCategory
        
        self.dateLabel.text = conversation.date
        self.timeLabel.text = "\(conversation.startTime) "
        
        self.calendarIcon.image = UIImage(systemName: "calendar")
        self.clockIcon.image = UIImage(systemName: "clock")
        self.calendarIcon.tintColor = .systemGray
        self.clockIcon.tintColor = .systemGray
        
        // Dynamic Category Icon Logic
        let iconName: String
        let tintColor: UIColor
        
       switch categoryString!.lowercased() {
        case "family":
            iconName = "heart.fill"
            tintColor = .systemRed
            categoryAccessibilityName = "Family"
        case "friends":
            iconName = "person.2.fill"
            tintColor = .systemOrange
            categoryAccessibilityName = "Friends"
        case "office", "work":
            iconName = "briefcase.fill"
            tintColor = .systemBlue
            categoryAccessibilityName = "Office"
        case "medical", "health":
            iconName = "cross.case.fill"
            tintColor = .systemGreen
            categoryAccessibilityName = "Medical"
        case "general":
            iconName = "note.text"
            tintColor = .systemGray
            categoryAccessibilityName = "General"
        default:
            iconName = "folder.fill"
            tintColor = .systemGray
            categoryAccessibilityName = "Uncategorized"
        }
        
        self.categoryIcon.image = UIImage(systemName: iconName)
        self.categoryIcon.tintColor = tintColor
        
        self.calendarIcon.isAccessibilityElement = true
        self.calendarIcon.accessibilityLabel = "Date: \(conversation.date)"
        
        self.clockIcon.isAccessibilityElement = true
        self.clockIcon.accessibilityLabel = " \(conversation.startTime) to \(conversation.endTime)"
        
        self.categoryIcon.isAccessibilityElement = true
        self.categoryIcon.accessibilityLabel = "Category: \(categoryAccessibilityName)"
    }
}
