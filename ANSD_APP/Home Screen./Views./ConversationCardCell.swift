//
//  ConversationCardCell.swift
//  Group_4-ANSD_App
//
//  Created by Daiwiik Harihar on 10/12/25.
//

import UIKit

class RoutineTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton?
    
    var onInfoTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDesign()
        infoButton?.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
    }

    func setupDesign() {
        iconImageView.contentMode = .scaleToFill
        iconImageView.layer.cornerRadius = 10
        iconImageView.backgroundColor = .systemGray6
        iconImageView.contentMode = .center
        iconImageView.clipsToBounds = true
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        self.selectionStyle = .default
    }

    func configure(with item: RoutineConversation) {
        titleLabel.text = item.conversationTopic
        timeLabel.text = item.timeRange
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
            iconImageView.tintColor = .systemGray6
        }
    }
    
    @objc private func infoButtonTapped() {
        onInfoTapped?()
    }
}

class ConversationCardCell: UITableViewCell {
    @IBOutlet weak var cardContainer: UIView!
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var metadataLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupDesign()
    }

    func setupDesign() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        cardContainer.layer.cornerRadius = 14
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.shadowColor = UIColor.black.cgColor
        cardContainer.layer.shadowOpacity = 0.08
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardContainer.layer.shadowRadius = 4
    }

    func configure(with item: RoutineConversation) {
        topicLabel.text = item.conversationTopic
        descriptionLabel.text = item.description ?? item.status
        
        let calendar = NSTextAttachment()
        calendar.image = UIImage(systemName: "calendar")?.withTintColor(.systemGray3)
        calendar.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        
        let clock = NSTextAttachment()
        clock.image = UIImage(systemName: "clock")?.withTintColor(.systemGray3)
        clock.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        
        let tag = NSTextAttachment()
        tag.image = UIImage(systemName: "tag.fill")?.withTintColor(.systemGray3)
        tag.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        
        let divider = NSAttributedString(
            string: " | ",
            attributes: [.foregroundColor: UIColor.tertiaryLabel]
        )
        
        let fullString = NSMutableAttributedString()
        
        if let dateText = item.date {
            fullString.append(NSAttributedString(attachment: calendar))
            fullString.append(NSAttributedString(string: " \(dateText)"))
            fullString.append(divider)
        }
        
        fullString.append(NSAttributedString(attachment: clock))
        fullString.append(NSAttributedString(string: " \(item.timeRange)"))
        fullString.append(divider)
        fullString.append(NSAttributedString(attachment: tag))
        fullString.append(NSAttributedString(string: " \(item.categoryTitle)"))
        
        metadataLabel.attributedText = fullString
        metadataLabel.textColor = .secondaryLabel
    }
}
