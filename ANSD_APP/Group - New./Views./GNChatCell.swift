import UIKit

class GNOutgoingCell: UICollectionViewCell {
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    private func setupCell() {
        bubbleView.backgroundColor = .systemBlue
        messageLabel.textColor = .white
        bubbleView.layer.cornerRadius = 16
        
        // Ensure the label wraps properly
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
        // 1. Force the label to expand vertically
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // 2. Fix the width of the contentView to prevent horizontal distortion
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            let widthConstraint = contentView.widthAnchor.constraint(equalToConstant: screenWidth - 32)
            widthConstraint.priority = UILayoutPriority(999)
            widthConstraint.isActive = true
        }
    }
}

class GNIncomingCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    private func setupCell() {
        bubbleView.backgroundColor = .systemGray5
        messageLabel.textColor = .black
        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        
        // Force label to expand vertically
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        nameLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        nameLabel.addGestureRecognizer(tap)
        
        // Fix width
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            let widthConstraint = contentView.widthAnchor.constraint(equalToConstant: screenWidth - 32)
            widthConstraint.priority = UILayoutPriority(999)
            widthConstraint.isActive = true
        }
    }
    
    @objc func handleTap() {
        onLabelTapped?()
    }
}
