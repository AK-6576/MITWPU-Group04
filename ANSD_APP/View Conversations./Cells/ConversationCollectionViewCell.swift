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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }
    
    // Updates layer colors when switching between Light/Dark mode
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = UIColor.systemGray5.cgColor
            layer.shadowColor = UIColor.black.cgColor
        }
    }
    
    // Handles layout updates for the shadow path to maintain performance
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath
    }
    
    private func setupAppearance() {
        backgroundColor = .secondarySystemGroupedBackground
        
        // Corner and Border styling
        layer.cornerRadius = 20
        layer.masksToBounds = false
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor
        
        // Shadow styling
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        
        // Rasterization improves scrolling performance by caching the shadow
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    // Populates the cell with conversation data and configures category-specific icons
    func configure(with conversation: Conversation) {
        titleLabel.text = conversation.title
        descriptionLabel.text = conversation.description
        dateLabel.text = conversation.date
        timeLabel.text = conversation.startTime
        
        // Configure standard icons
        calendarIcon.image = UIImage(systemName: "calendar")
        clockIcon.image = UIImage(systemName: "clock")
        calendarIcon.tintColor = .systemGray
        clockIcon.tintColor = .systemGray
        
        configureCategory(for: conversation.category)
        configureAccessibility(for: conversation)
    }
    
    // logic for category icon, color, and label
    private func configureCategory(for categoryString: String) {
        let categoryLower = categoryString.lowercased()
        
        // Auto-capitalize the display label (e.g. "family" -> "Family")
        categoryLabel.text = categoryString.capitalized
        
        let iconName: String
        let tintColor: UIColor
        
        switch categoryLower {
        case "family":
            iconName = "figure.2.and.child.holdinghands"
            tintColor = .systemRed
        case "friends":
            iconName = "person.2.fill"
            tintColor = .systemOrange
        case "office", "work":
            iconName = "briefcase.fill"
            tintColor = .systemBlue
        case "medical", "health":
            iconName = "cross.case.fill"
            tintColor = .systemGreen
        case "general":
            iconName = "note.text"
            tintColor = .systemGray
        default:
            iconName = "folder.fill"
            tintColor = .systemGray
        }
        
        categoryIcon.image = UIImage(systemName: iconName)
        categoryIcon.tintColor = tintColor
    }
    
    // Sets up Accessibility on the Cell itself for a better VoiceOver experience
    private func configureAccessibility(for conversation: Conversation) {
        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        
        let categoryName = categoryLabel.text ?? "Uncategorized"
        
        // Reads a natural sentence: "Family meeting about vacation, Category Family, October 24th at 2 PM"
        self.accessibilityLabel = """
        \(conversation.title).
        \(conversation.description).
        Category: \(categoryName).
        Scheduled for \(conversation.date) at \(conversation.startTime).
        """
        
        self.accessibilityHint = "Double tap to view conversation details."
        
        // Hide internal elements since the parent cell now describes them
        titleLabel.isAccessibilityElement = false
        descriptionLabel.isAccessibilityElement = false
        calendarIcon.isAccessibilityElement = false
        clockIcon.isAccessibilityElement = false
    }
}
