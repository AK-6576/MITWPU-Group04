//
//  QuickActionCell.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 16/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class QuickActionCell: UITableViewCell {

    // MARK: - Storyboard Outlets (kept for IB compatibility)
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!

    // MARK: - Programmatic Views
    private let timeLabelRight = UILabel()
    private let todayBadgeLabel = UILabel()
    private let todayBadgeContainer = UIView()

    var onInfoTapped: (() -> Void)?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupIconStyle()
        setupRightSideViews()
    }

    // MARK: - Icon Setup

    private func setupIconStyle() {
        guard let icon = iconImageView else { return }
        icon.layer.cornerRadius = 12
        icon.clipsToBounds = true
        icon.contentMode = .center
    }

    // MARK: - Right-side programmatic views

    private func setupRightSideViews() {
        // Time label (right side, e.g. "9:00 AM")
        timeLabelRight.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        timeLabelRight.textColor = .secondaryLabel
        timeLabelRight.textAlignment = .right
        timeLabelRight.translatesAutoresizingMaskIntoConstraints = false

        // "Today" badge
        todayBadgeContainer.layer.cornerRadius = 8
        todayBadgeContainer.clipsToBounds = true
        todayBadgeContainer.translatesAutoresizingMaskIntoConstraints = false

        todayBadgeLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        todayBadgeLabel.textColor = .white
        todayBadgeLabel.textAlignment = .center
        todayBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        todayBadgeContainer.addSubview(todayBadgeLabel)

        contentView.addSubview(timeLabelRight)
        contentView.addSubview(todayBadgeContainer)

        NSLayoutConstraint.activate([
            // Badge label inside container (padding)
            todayBadgeLabel.topAnchor.constraint(equalTo: todayBadgeContainer.topAnchor, constant: 3),
            todayBadgeLabel.bottomAnchor.constraint(equalTo: todayBadgeContainer.bottomAnchor, constant: -3),
            todayBadgeLabel.leadingAnchor.constraint(equalTo: todayBadgeContainer.leadingAnchor, constant: 8),
            todayBadgeLabel.trailingAnchor.constraint(equalTo: todayBadgeContainer.trailingAnchor, constant: -8),

            // Time label — pin to right of cell, above centre
            timeLabelRight.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            timeLabelRight.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),

            // Badge — below time label
            todayBadgeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            todayBadgeContainer.topAnchor.constraint(equalTo: timeLabelRight.bottomAnchor, constant: 5),
        ])

        // Constrain existing title/subtitle labels to leave room on the right
        DispatchQueue.main.async { [weak self] in
            self?.constrainLabelsAwayFromRight()
        }
    }

    private func constrainLabelsAwayFromRight() {
        guard let titleLabel = titleLabel, let subtitleLabel = subtitleLabel else { return }

        // Remove any existing trailing constraints on the labels pointing to cell trailing
        for constraint in contentView.constraints {
            if (constraint.firstItem as? UIView == titleLabel || constraint.secondItem as? UIView == titleLabel ||
                constraint.firstItem as? UIView == subtitleLabel || constraint.secondItem as? UIView == subtitleLabel),
               constraint.firstAttribute == .trailing || constraint.secondAttribute == .trailing {
                constraint.isActive = false
            }
        }

        // Add new trailing constraint so text doesn't overlap right-side info
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabelRight.leadingAnchor, constant: -8),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabelRight.leadingAnchor, constant: -8),
        ])
    }

    // MARK: - Configure

    func configure(with item: RoutineConversation) {
        // Title
        titleLabel?.text = item.conversationTopic

        // Subtitle: "Category · N participants"
        let participantCount = item.participantNames.count
        let participantText = participantCount == 1 ? "1 participant" : "\(participantCount) participants"
        subtitleLabel?.text = "\(item.categoryTitle) · \(participantText)"
        subtitleLabel?.textColor = .secondaryLabel
        subtitleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)

        // Title font
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        // Icon
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        if let image = UIImage(systemName: item.iconName, withConfiguration: config) {
            iconImageView?.image = image.withRenderingMode(.alwaysTemplate)
        }

        // Icon background color based on category
        let color = getColorForCategory(item.categoryTitle)
        iconImageView?.tintColor = color
        iconImageView?.backgroundColor = color.withAlphaComponent(0.15)
        iconImageView?.layer.cornerRadius = 12

        // Right-side time
        timeLabelRight.text = item.startTime

        // "Today" badge — always show Today for items returned by getUpcomingActions
        todayBadgeLabel.text = "Today"
        todayBadgeContainer.backgroundColor = color
    }
}
