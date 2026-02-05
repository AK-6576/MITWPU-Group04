import UIKit

/// A single class to handle all 'Info' or 'Note' popups across Family, Friends, and Office modules.
class InfoViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - Properties
    var existingNote: String?
    
    /// A callback closure to send the edited text back to the parent view controller.
    var onSave: ((String) -> Void)?
    
    // MARK: - Outlets
    @IBOutlet weak var textView: UITextView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        guard let tv = textView else { return }
        tv.delegate = self
        tv.text = existingNote
        
        // Basic styling to ensure it looks like a clean note-taking area
        tv.layer.cornerRadius = 8
        tv.layer.borderWidth = 0.5
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Automatically open keyboard for better UX
        tv.becomeFirstResponder()
    }

    // MARK: - Actions
    @IBAction func closeButtonTapped(_ sender: Any) {
        // REDUNDANCY RESOLVED:
        // We now trigger the save closure automatically so the user's edits aren't lost.
        if let updatedText = textView?.text {
            onSave?(updatedText)
        }
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Storyboard Compatibility Aliases
// These allow your existing Storyboard "Class" settings to keep working.
typealias InfoViewController1 = InfoViewController
typealias FriendsInfoViewController = InfoViewController
typealias OfficeInfoViewController = InfoViewController
