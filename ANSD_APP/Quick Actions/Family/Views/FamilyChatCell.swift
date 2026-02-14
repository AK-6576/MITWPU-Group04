import UIKit

// MARK: - 1. Base Chat Cell (The Engine)
class BaseChatCell: UICollectionViewCell {
    
    var widthConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupWidthConstraint()
    }

    private func setupWidthConstraint() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let screenWidth = windowScene.screen.bounds.width
            widthConstraint = contentView.widthAnchor.constraint(equalToConstant: screenWidth)
            widthConstraint?.isActive = true
        }
    }

    /// Common styling for all chat bubbles
    func applyBaseBubbleStyle(view: UIView) {
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var newFrame = layoutAttributes.frame
        newFrame.size.height = ceil(size.height)
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }
}

// MARK: - 2. Outgoing Cell
class OutgoingCell: BaseChatCell {
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyBaseBubbleStyle(view: bubbleView)
        
        bubbleView.backgroundColor = .systemBlue
        messageLabel.textColor = .white
        
        // Tail effect: Bottom-right stays square
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
    }
}

// MARK: - 3. Incoming Cell
class IncomingCell: BaseChatCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var onLabelTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyBaseBubbleStyle(view: bubbleView)
        
        bubbleView.backgroundColor = .systemGray5
        messageLabel.textColor = .black
        
        // Tail effect: Bottom-left stays square
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        setupUI()
    }
    
    private func setupUI() {
        // Name tap gesture
        nameLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        nameLabel.addGestureRecognizer(tap)
        
        // Profile Image circularity logic consolidated
        if let profileImg = profileImageView {
            profileImg.layer.cornerRadius = profileImg.frame.height / 2
            profileImg.clipsToBounds = true
            profileImg.contentMode = .scaleAspectFill
            profileImg.backgroundColor = .systemGray4
        }
    }
    
    @objc private func handleTap() {
        onLabelTapped?()
    }
}

// MARK: - 4. Storyboard Compatibility Aliases
typealias OutgoingCell2 = OutgoingCell
typealias IncomingCell2 = IncomingCell
