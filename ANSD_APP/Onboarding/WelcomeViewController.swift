import UIKit

class WelcomeViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var appleSignInButton: UIButton!
    @IBOutlet weak var googleSignInButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Logo styling
        logoImageView.layer.cornerRadius = 20
        logoImageView.clipsToBounds = true
        
        // Apple Sign In (Black with rounded corners)
        appleSignInButton.layer.cornerRadius = 28
        appleSignInButton.backgroundColor = .black
        appleSignInButton.setTitleColor(.white, for: .normal)
        
        // Google Sign In (Bordered/White)
        googleSignInButton.layer.cornerRadius = 28
        googleSignInButton.layer.borderWidth = 1
        googleSignInButton.layer.borderColor = UIColor.systemGray4.cgColor
    }

    // MARK: - Actions
    @IBAction func appleSignInTapped(_ sender: UIButton) {
        print("Apple Sign In initiated")
    }
    
    @IBAction func googleSignInTapped(_ sender: UIButton) {
        print("Google Sign In initiated")
    }
    
    @IBAction func createAccountTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showCreateAccount", sender: self)
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showLoginAccount", sender: self)
    }
}
