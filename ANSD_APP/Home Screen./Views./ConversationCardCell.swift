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
        iconImageView.contentMode = .scaleToFill
        iconImageView.layer.cornerRadius = 10
        iconImageView.backgroundColor = .systemGray6 // Added a light background so color pops
        iconImageView.contentMode = .center // Keeps icon centered in box
        iconImageView.clipsToBounds = true
        
        // 2. Text Styling
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        
        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        
        // 3. Selection Style
        self.selectionStyle = .default
    }

    func configure(with item: RoutineConversation) {
        titleLabel.text = item.conversationTopic
        timeLabel.text = item.timeRange
        
        // --- 1. IMAGE CONFIGURATION ---
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        
        // ★ CRITICAL FIX: .alwaysTemplate forces the image to ignore its native color
        // and paint itself with the tintColor we set below.
        if let image = UIImage(systemName: item.iconName, withConfiguration: config) {
            iconImageView.image = image.withRenderingMode(.alwaysTemplate)
        }
        
        // --- 2. DYNAMIC COLOR LOGIC ---
        // This sets the color based on the category (Office, Family, etc.)
        switch item.categoryTitle {
        case "Office":
            iconImageView.tintColor = .systemBlue
        case "Family":
            iconImageView.tintColor = .systemPink
        case "Friends":
            iconImageView.tintColor = .systemGreen
        default:
            iconImageView.tintColor = .systemGray6
        }
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

