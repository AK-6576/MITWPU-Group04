import UIKit

/// A single, reusable cell class for all routine-based tables (Family, Friends, Office).
class RoutineTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // Ensuring labels handle multiple lines if needed
        titleLabel?.numberOfLines = 0
        subtitleLabel?.numberOfLines = 0
        
        // Visual polish for a 'card' list appearance
        selectionStyle = .none
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        subtitleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel?.textColor = .secondaryLabel
    }

    /// REDUNDANCY RESOLVED:
    /// Instead of passing multiple strings, we pass the protocol-conforming object.
    /// This works for FamilyRoutineItem, FriendRoutineItem, and RoutineItem.
    func configure(with item: RoutineItemProtocol) {
        titleLabel.text = item.title
        subtitleLabel.text = item.time
    }
    
    /// Keep this for cases where you might want to manually set text (like headers)
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}

// MARK: - Storyboard Compatibility Aliases
// Maps legacy class names in Storyboard to this single unified class.
typealias RoutineTableViewCell1 = RoutineTableViewCell
typealias FriendsRoutineTableViewCell = RoutineTableViewCell
typealias OfficeRoutineTableViewCell = RoutineTableViewCell
