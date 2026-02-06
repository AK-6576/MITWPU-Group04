import UIKit
import Supabase

class AuthViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var dobTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var hearingLevelSlider: UISlider!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        loadingIndicator.hidesWhenStopped = true
        passwordTextField.isSecureTextEntry = true
        
        // Styling to match your provided Storyboard screenshot
        [fullNameTextField, emailTextField, dobTextField, phoneNumberTextField, passwordTextField].forEach {
            $0?.layer.borderWidth = 1.0
            $0?.layer.borderColor = UIColor.black.cgColor
            $0?.layer.cornerRadius = 4.0
        }
    }

    // MARK: - IBActions
    @IBAction func signUpTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let name = fullNameTextField.text else {
            showAlert(message: "Please fill in all required fields.")
            return
        }

        // This metadata matches your Storyboard fields
        let metadata: [String: Any] = [
            "full_name": name,
            "date_of_birth": dobTextField.text ?? "",
            "phone": phoneNumberTextField.text ?? "",
            "hearing_level": Int(hearingLevelSlider.value) // Slider value converted to Int
        ]

        toggleLoading(true)

        Task {
            do {
                try await SupabaseManager.shared.signUp(
                    email: email,
                    password: password,
                    metadata: metadata
                )
                
                await MainActor.run {
                    toggleLoading(false)
                    self.showAlert(title: "Success", message: "Account created! Check your email to verify.") {
                        self.navigateToHome()
                    }
                }
            } catch {
                await MainActor.run {
                    toggleLoading(false)
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Navigation
    private func navigateToHome() {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeVC = storyboard.instantiateInitialViewController()
        
        if let window = self.view.window {
            window.rootViewController = homeVC
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }

    private func toggleLoading(_ isLoading: Bool) {
        signUpButton.isEnabled = !isLoading
        isLoading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
    }

    private func showAlert(title: String = "Error", message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
