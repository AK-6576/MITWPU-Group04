//
//  QuickActionCell.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 16/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class QuickActionCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!

    var onInfoTapped: (() -> Void)?

    private let customIconContainer = UIView()
    private let customIconImageView = UIImageView()
    private let textStackView      = UIStackView()
    private let customTitleLabel   = UILabel()
    private let customSubtitleLabel = UILabel()
    private let rightStackView     = UIStackView()
    private let customTimeLabel    = UILabel()
    private let badgeContainer     = UIView()
    private let badgeLabel         = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupDesign()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        // Hide storyboard views
        titleLabel?.isHidden = true
        subtitleLabel?.isHidden = true
        iconImageView?.isHidden = true

        setupDesign()
    }

    private func setupDesign() {
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.contentView.alpha = 1.0
        self.alpha = 1.0

        // ── Custom Icon ─────────────────────────────────
        customIconContainer.layer.cornerRadius        = 10
        customIconContainer.clipsToBounds             = true
        customIconContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(customIconContainer)

        customIconImageView.contentMode               = .scaleAspectFit
        customIconImageView.translatesAutoresizingMaskIntoConstraints = false
        customIconContainer.addSubview(customIconImageView)

        // ── Text Stack ─────────────────────────────────
        customTitleLabel.font                         = .systemFont(ofSize: 17, weight: .semibold)
        customTitleLabel.textColor                    = .label

        customSubtitleLabel.font                            = .systemFont(ofSize: 14, weight: .regular)
        customSubtitleLabel.textColor                       = .secondaryLabel

        textStackView.axis                            = .vertical
        textStackView.spacing                         = 2
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubview(customTitleLabel)
        textStackView.addArrangedSubview(customSubtitleLabel)
        contentView.addSubview(textStackView)

        // ── Right Stack (time + badge) ─────────────────
        customTimeLabel.font                          = .systemFont(ofSize: 13, weight: .semibold)
        customTimeLabel.textColor                     = .secondaryLabel
        customTimeLabel.textAlignment                 = .right

        badgeLabel.font                               = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.layer.cornerRadius             = 6
        badgeContainer.clipsToBounds                  = true
        badgeContainer.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.addSubview(badgeLabel)

        rightStackView.axis                           = .vertical
        rightStackView.spacing                        = 6
        rightStackView.alignment                      = .trailing
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.addArrangedSubview(customTimeLabel)
        rightStackView.addArrangedSubview(badgeContainer)
        contentView.addSubview(rightStackView)

        // ── Constraints ────────────────────────────────
        NSLayoutConstraint.activate([
            // Icon
            customIconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            customIconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            customIconContainer.widthAnchor.constraint(equalToConstant: 44),
            customIconContainer.heightAnchor.constraint(equalToConstant: 44),

            customIconImageView.centerXAnchor.constraint(equalTo: customIconContainer.centerXAnchor),
            customIconImageView.centerYAnchor.constraint(equalTo: customIconContainer.centerYAnchor),
            customIconImageView.widthAnchor.constraint(equalToConstant: 22),
            customIconImageView.heightAnchor.constraint(equalToConstant: 22),

            // Text stack
            textStackView.leadingAnchor.constraint(equalTo: customIconContainer.trailingAnchor, constant: 12),
            textStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // Right stack (time + badge)
            rightStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            rightStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightStackView.leadingAnchor.constraint(greaterThanOrEqualTo: textStackView.trailingAnchor, constant: 8),

            // Badge label padding
            badgeLabel.topAnchor.constraint(equalTo: badgeContainer.topAnchor, constant: 3),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor, constant: -3),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor, constant: 8),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor, constant: -8)
        ])
    }

    func configure(with item: RoutineConversation) {
        customTitleLabel.text = item.conversationTopic

        let paxCount = item.participantNames.count
        customSubtitleLabel.text = "\(item.categoryTitle) • \(paxCount) participants"

        customTimeLabel.text = item.startTime

        // Determine Upcoming vs Scheduled based on time
        let badgeText = QuickActionCell.isUpcoming(item: item) ? "Upcoming" : "Scheduled"
        badgeLabel.text = badgeText

        let config = UIImage.SymbolConfiguration(weight: .semibold)
        if let image = UIImage(systemName: item.iconName, withConfiguration: config) {
            customIconImageView.image = image.withRenderingMode(.alwaysTemplate)
        }

        let tintColor = getColorForCategory(item.categoryTitle)

        badgeContainer.backgroundColor = .secondarySystemFill
        badgeLabel.textColor = .label

        customIconContainer.backgroundColor = tintColor.withAlphaComponent(0.15)
        customIconImageView.tintColor = tintColor
    }

    // MARK: - Helper for filtering
    static func isUpcoming(item: RoutineConversation) -> Bool {
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        df.locale = Locale(identifier: "en_US_POSIX")

        if let targetDate = df.date(from: item.startTime) {
            let now = Date()
            let cal = Calendar.current
            var tComps = cal.dateComponents([.hour, .minute], from: targetDate)
            let nComps = cal.dateComponents([.year, .month, .day], from: now)
            tComps.year = nComps.year
            tComps.month = nComps.month
            tComps.day = nComps.day

            if let combinedTarget = cal.date(from: tComps) {
                let diff = combinedTarget.timeIntervalSince(now)
                // Upcoming is within next 4 hours
                return diff > 0 && diff <= 3600 * 4
            }
        }
        return false
    }
}
