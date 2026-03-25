//
//  ConversationCollectionViewCell.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// MARK: - Conversation Collection View Cell
// Specialized cell for displaying conversation summaries, including topic, date, time, and category icons.
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
        contentView.backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 16
        layer.masksToBounds = true
        layer.shadowOpacity = 0
        layer.borderWidth = 0
        
        // HIG: Truncate summary to exactly one line to keep cards compact and uniform.
        descriptionLabel.numberOfLines = 1
        
        // HIG: Enforce strong typographic hierarchy and spacing.
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        // Shrunk text size to '.footnote' to perfectly fit deep hierarchy requested
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        descriptionLabel.textColor = .secondaryLabel
        
        // We will unhide and creatively repurpose these perfectly-spaced icons dynamically.
        calendarIcon.isHidden = false
        clockIcon.isHidden = false
    }
    
    func configure(with conversation: Conversation) {
        if conversation.isPinned {
            let fullString = NSMutableAttributedString(string: conversation.title + " ")
            let imageAttachment = NSTextAttachment()
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            if let image = UIImage(systemName: "pin.fill", withConfiguration: config)?.withTintColor(.systemOrange, renderingMode: .alwaysOriginal) {
                imageAttachment.image = image
                imageAttachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
            }
            fullString.append(NSAttributedString(attachment: imageAttachment))
            titleLabel.attributedText = fullString
        } else {
            titleLabel.text = conversation.title
        }
        descriptionLabel.text = conversation.details
        
        // HIG: Removed repetitive Date & Time. Repurposing these slots based on user priority (Participants, Duration, Category)
        
        // Slot 1 (Left): Participants
        let paxCount = conversation.participants?.count ?? 0
        dateLabel.text = "\(paxCount) People"
        calendarIcon.image = UIImage(systemName: "person.2.fill")
        calendarIcon.tintColor = .secondaryLabel // Increased emphasis slightly
        
        // Slot 2 (Middle): Duration
        let durationStr = calculateDuration(start: conversation.startTime, end: conversation.endTime)
        timeLabel.text = durationStr
        clockIcon.image = UIImage(systemName: "timer")
        clockIcon.tintColor = .secondaryLabel
        
        let categoryString = conversation.category
        let capitalizedCategory = categoryString.prefix(1).uppercased() + categoryString.dropFirst()
        categoryLabel.text = capitalizedCategory
        
        // Enforcing proper scale down for metadata
        dateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        timeLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        categoryLabel.font = UIFont.preferredFont(forTextStyle: .footnote) // slightly larger for category to stand out
        
        let iconName: String
        let tintColor: UIColor
        
        switch categoryString {
        case "Family":
            iconName = "figure.2.and.child.holdinghands"
            tintColor = .systemRed
            categoryAccessibilityName = "Family"
        case "Friends":
            iconName = "person.2.fill"
            tintColor = .systemOrange
            categoryAccessibilityName = "Friends"
        case "Office", "Work":
            iconName = "briefcase.fill"
            tintColor = .systemBlue
            categoryAccessibilityName = "Office"
        case "Medical", "Health":
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
        case "Group-Join":
            iconName = "person.bubble"
            tintColor = .systemBlue
            categoryAccessibilityName = "Group-Join"
        case "Group-New":
            iconName = "square.and.pencil"
            tintColor = .systemBlue
            categoryAccessibilityName = "Group-New"
        default:
            iconName = "folder.fill"
            tintColor = .systemGray
            categoryAccessibilityName = "Uncategorized"
        }
        
        categoryIcon.image = UIImage(systemName: iconName)
        categoryIcon.tintColor = tintColor
        
        calendarIcon.isAccessibilityElement = true
        calendarIcon.accessibilityLabel = "\(paxCount) Participants"
        
        clockIcon.isAccessibilityElement = true
        clockIcon.accessibilityLabel = "Duration: \(durationStr)"
        
        categoryIcon.isAccessibilityElement = true
        categoryIcon.accessibilityLabel = "Category: \(categoryAccessibilityName)"
    }
    
    // HIG: Helper to calculate accurate duration
    private func calculateDuration(start: String, end: String) -> String {
        guard !start.isEmpty, !end.isEmpty else { return "Unknown" }
        
        let formatters = ["h:mm a", "HH:mm", "hh:mm a", "H:mm"]
        var sDate: Date?
        var eDate: Date?
        
        for format in formatters {
            let df = DateFormatter()
            df.dateFormat = format
            if sDate == nil { sDate = df.date(from: start) }
            if eDate == nil { eDate = df.date(from: end) }
            if sDate != nil && eDate != nil { break }
        }
        
        if let sDate = sDate, let eDate = eDate {
            var diffOptions = eDate.timeIntervalSince(sDate)
            if diffOptions < 0 { diffOptions += 24 * 3600 } // Handles crossing midnight
            let totalMins = Int(diffOptions) / 60
            if totalMins >= 60 {
                let hours = totalMins / 60
                let mins = totalMins % 60
                return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
            }
            return "\(totalMins)m"
        }
        return "\(start) - \(end)" // Fallback if format misses
    }
}
