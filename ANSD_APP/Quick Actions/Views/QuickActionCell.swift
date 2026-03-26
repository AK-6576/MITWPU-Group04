//
//  QuickActionCell.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 16/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class QuickActionCell: UITableViewCell {

    // MARK: - Legacy Outlets (kept for Storyboard compatibility)
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!

    // MARK: - Programmatic Views
    private let cardContainer      = UIView()
    var isFirstRow = false
    var isLastRow = false
    private let outlinelayer = CAShapeLayer()
    private let customIconContainer = UIView()
    private let customIconImageView = UIImageView()
    private let textStackView      = UIStackView()
    private let customTitleLabel   = UILabel()
    private let customSubtitleLabel = UILabel()
    private let rightStackView     = UIStackView()
    private let customTimeLabel    = UILabel()
    private let badgeContainer     = UIView()
    private let badgeLabel         = UILabel()
    private let chevronImageView   = UIImageView()
    private let separator          = UIView()

    var onInfoTapped: (() -> Void)? // Kept for compatibility

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Hide legacy storyboard labels
        titleLabel?.isHidden = true
        titleLabel?.alpha = 0
        subtitleLabel?.isHidden = true
        subtitleLabel?.alpha = 0
        iconImageView?.isHidden = true
        iconImageView?.alpha = 0
        
        setupDesign()
    }

    // MARK: - Setup Design (Replicates Home Screen QuickActionTableViewCell)

    func setupDesign() {
        backgroundColor              = .clear
        contentView.backgroundColor  = .clear
        selectionStyle               = .none
        accessoryType                = .none

        // ── Card Container ──────────────────────────────
        cardContainer.backgroundColor                 = .secondarySystemGroupedBackground
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardContainer)

        // ── Custom Icon ─────────────────────────────────
        customIconContainer.layer.cornerRadius        = 10
        customIconContainer.clipsToBounds             = true
        customIconContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(customIconContainer)

        customIconImageView.contentMode               = .scaleAspectFit
        customIconImageView.translatesAutoresizingMaskIntoConstraints = false
        customIconContainer.addSubview(customIconImageView)

        // ── Text Stack ─────────────────────────────────
        customTitleLabel.font                         = .systemFont(ofSize: 17, weight: .semibold)
        customTitleLabel.textColor                    = .label

        customSubtitleLabel.font                      = .systemFont(ofSize: 14, weight: .regular)
        customSubtitleLabel.textColor                 = .secondaryLabel

        textStackView.axis                            = .vertical
        textStackView.spacing                         = 2
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubview(customTitleLabel)
        textStackView.addArrangedSubview(customSubtitleLabel)
        cardContainer.addSubview(textStackView)

        // ── Chevron ────────────────────────────────────
        let chevCfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevronImageView.image                        = UIImage(systemName: "chevron.right", withConfiguration: chevCfg)
        chevronImageView.tintColor                    = .systemGray3
        chevronImageView.contentMode                  = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(chevronImageView)

        // ── Right Stack (time + badge) ─────────────────
        customTimeLabel.font                          = .systemFont(ofSize: 13, weight: .semibold)
        customTimeLabel.textColor                     = .secondaryLabel

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
        cardContainer.addSubview(rightStackView)

        // ── Internal Separator ─────────────────────────
        separator.backgroundColor                     = UIColor.systemGray5
        separator.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(separator)

        // ── Constraints ────────────────────────────────
        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 76),

            customIconContainer.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 14),
            customIconContainer.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            customIconContainer.widthAnchor.constraint(equalToConstant: 44),
            customIconContainer.heightAnchor.constraint(equalToConstant: 44),

            customIconImageView.centerXAnchor.constraint(equalTo: customIconContainer.centerXAnchor),
            customIconImageView.centerYAnchor.constraint(equalTo: customIconContainer.centerYAnchor),
            customIconImageView.widthAnchor.constraint(equalToConstant: 22),
            customIconImageView.heightAnchor.constraint(equalToConstant: 22),

            textStackView.leadingAnchor.constraint(equalTo: customIconContainer.trailingAnchor, constant: 12),
            textStackView.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),

            chevronImageView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -14),
            chevronImageView.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 10),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14),

            rightStackView.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -10),
            rightStackView.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            rightStackView.leadingAnchor.constraint(greaterThanOrEqualTo: textStackView.trailingAnchor, constant: 8),

            badgeLabel.topAnchor.constraint(equalTo: badgeContainer.topAnchor, constant: 3),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor, constant: -3),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor, constant: 8),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor, constant: -8),

            separator.leadingAnchor.constraint(equalTo: textStackView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    
    // MARK: - Corner Rounding + Border

    func applyCornerRounding(isFirst: Bool, isLast: Bool) {
        self.isFirstRow = isFirst
        self.isLastRow = isLast
        
        var corners: CACornerMask = []
        if isFirst { corners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if isLast  { corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }

        cardContainer.layer.cornerRadius    = (isFirst || isLast) ? 16 : 0
        cardContainer.layer.maskedCorners   = corners
        cardContainer.clipsToBounds         = true

        cardContainer.layer.borderWidth     = 0
        separator.isHidden = isLast
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if outlinelayer.superlayer == nil {
            outlinelayer.fillColor = UIColor.clear.cgColor
            outlinelayer.strokeColor = UIColor.systemGray4.cgColor
            outlinelayer.lineWidth = 0.5
            cardContainer.layer.addSublayer(outlinelayer)
        }
        
        let path = UIBezierPath()
        let bounds = cardContainer.bounds
        let r = cardContainer.layer.cornerRadius
        
        path.move(to: CGPoint(x: 0, y: isFirstRow ? r : 0))
        path.addLine(to: CGPoint(x: 0, y: isLastRow ? bounds.height - r : bounds.height))
        
        if isLastRow {
            path.addArc(withCenter: CGPoint(x: r, y: bounds.height - r), radius: r, startAngle: .pi, endAngle: .pi / 2, clockwise: false)
            path.addLine(to: CGPoint(x: bounds.width - r, y: bounds.height))
            path.addArc(withCenter: CGPoint(x: bounds.width - r, y: bounds.height - r), radius: r, startAngle: .pi / 2, endAngle: 0, clockwise: false)
        } else {
            path.move(to: CGPoint(x: bounds.width, y: bounds.height))
        }
        
        path.addLine(to: CGPoint(x: bounds.width, y: isFirstRow ? r : 0))
        
        if isFirstRow {
            path.addArc(withCenter: CGPoint(x: bounds.width - r, y: r), radius: r, startAngle: 0, endAngle: -.pi / 2, clockwise: false)
            path.addLine(to: CGPoint(x: r, y: 0))
            path.addArc(withCenter: CGPoint(x: r, y: r), radius: r, startAngle: -.pi / 2, endAngle: -.pi, clockwise: false)
        }
        
        outlinelayer.path = path.cgPath
    }

    // MARK: - Configure

    func configure(with item: RoutineConversation, isFirst: Bool = true, isLast: Bool = true) {
        applyCornerRounding(isFirst: isFirst, isLast: isLast)
        
        customTitleLabel.text = item.conversationTopic
        let paxCount = item.participantNames.count
        customSubtitleLabel.text = "\(item.categoryTitle) • \(paxCount) participants"
        
        customTimeLabel.text = item.startTime
        
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        df.locale = Locale(identifier: "en_US_POSIX")
        var badgeText = "Scheduled"
        
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
                if diff > 0 && diff <= 3600 * 4 {
                    badgeText = "Upcoming"
                }
            }
        }
        badgeLabel.text = badgeText
        
        let config = UIImage.SymbolConfiguration(weight: .semibold)
        if let image = UIImage(systemName: item.iconName, withConfiguration: config) {
            customIconImageView.image = image.withRenderingMode(.alwaysTemplate)
        }
        
        var tintColor: UIColor = .systemGray
        switch item.categoryTitle {
        case "Office": tintColor = .systemBlue
        case "Family": tintColor = .systemGreen
        case "Friends": tintColor = .systemOrange
        default: tintColor = .systemGray
        }
        
        if badgeText == "Upcoming" {
            badgeContainer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
            badgeLabel.textColor = .systemRed
        } else {
            badgeContainer.backgroundColor = tintColor.withAlphaComponent(0.15)
            badgeLabel.textColor = tintColor
        }
        
        customIconContainer.backgroundColor = tintColor.withAlphaComponent(0.15)
        customIconImageView.tintColor = tintColor
    }
}
