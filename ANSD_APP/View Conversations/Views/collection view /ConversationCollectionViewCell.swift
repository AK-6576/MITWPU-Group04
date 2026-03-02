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

        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 20
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    func configure(with conversation: Conversation) {
        titleLabel.text = conversation.title
        descriptionLabel.text = conversation.details
        
        let categoryString = conversation.category
        let capitalizedCategory = categoryString.prefix(1).uppercased() + categoryString.dropFirst()
        categoryLabel.text = capitalizedCategory
        
        dateLabel.text = conversation.date
        timeLabel.text = "\(conversation.startTime)"
        
        calendarIcon.image = UIImage(systemName: "calendar")
        clockIcon.image = UIImage(systemName: "clock")
        calendarIcon.tintColor = .systemGray
        clockIcon.tintColor = .systemGray
        
        let iconName: String
        let tintColor: UIColor
        
        switch categoryString {
        case "family":
            iconName = "figure.2.and.child.holdinghands"
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
        case "Quick Captions":
            iconName = "waveform"
            tintColor = .systemBlue
            categoryAccessibilityName = "Quick Captions"
        case "Group Join":
            iconName = "person.bubble"
            tintColor = .systemBlue
            categoryAccessibilityName = "Group Join"
        case "Group New":
            iconName = "square.and.pencil"
            tintColor = .systemBlue
            categoryAccessibilityName = "Group New"
        default:
            iconName = "folder.fill"
            tintColor = .systemGray
            categoryAccessibilityName = "Uncategorized"
        }
        
        categoryIcon.image = UIImage(systemName: iconName)
        categoryIcon.tintColor = tintColor
        
        calendarIcon.isAccessibilityElement = true
        calendarIcon.accessibilityLabel = "Date: \(conversation.date)"
        
        clockIcon.isAccessibilityElement = true
        clockIcon.accessibilityLabel = " \(conversation.startTime) to \(conversation.endTime)"
        
        categoryIcon.isAccessibilityElement = true
        categoryIcon.accessibilityLabel = "Category: \(categoryAccessibilityName)"
    }
}
