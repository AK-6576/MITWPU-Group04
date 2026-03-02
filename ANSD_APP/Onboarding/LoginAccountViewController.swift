import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
    }

    private func setupUI() {
        // Style the login button
        loginButton.layer.cornerRadius = 28
        loginButton.clipsToBounds = true
        
        // Style the text fields
        let fields = [emailTextField, passwordTextField]
        for field in fields {
            guard let field = field else { continue }
            field.layer.cornerRadius = 12
            field.backgroundColor = .systemGray6
            field.borderStyle = .none
            
            // Add padding
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: field.frame.height))
            field.leftView = paddingView
            field.leftViewMode = .always
        }
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        // 1. Basic Validation
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }

        let details = ["email": email, "password": password]

        // 2. Call FirebaseManager
        FirebaseManager.shared.loginUser(details: details) { [weak self] result in
            switch result {
            case .success(let user):
                print("Successfully logged in: \(user.uid)")
                self?.performSegue(withIdentifier: "loginToHome", sender: self)
                
            case .failure(let error):
                self?.showAlert(message: error.localizedDescription)
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Login Issue", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}

// MARK: - Keyboard Handling
extension LoginViewController {
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
