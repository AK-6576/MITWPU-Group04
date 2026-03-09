//
//  LoginAccountViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 19/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Sign In"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        setupUI()
        setupTextFieldDelegates()
        setupKeyboardDismiss()
    }

    // MARK: - UI Setup
    
    private func setupUI() {
        // Style the Sign In button
        loginButton.layer.cornerRadius = 14
        loginButton.clipsToBounds = true
        
        // Style the text fields with consistent rounded look
        let fields = [emailTextField, passwordTextField]
        for field in fields {
            guard let field = field else { continue }
            field.layer.cornerRadius = 12
            field.backgroundColor = .systemGray6
            field.borderStyle = .none
            
            // Add left padding
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: field.frame.height))
            field.leftView = paddingView
            field.leftViewMode = .always
        }
        
        // Configure email field
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.returnKeyType = .next
        emailTextField.textContentType = .emailAddress
        emailTextField.placeholder = "john@example.com"
        
        // Configure password field
        passwordTextField.isSecureTextEntry = true
        passwordTextField.returnKeyType = .done
        passwordTextField.textContentType = .password
        passwordTextField.placeholder = "••••••••"
    }
    
    private func setupTextFieldDelegates() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            passwordTextField.resignFirstResponder()
            loginTapped(loginButton)
        }
        return true
    }

    // MARK: - Actions

    @IBAction func loginTapped(_ sender: UIButton) {
        // Dismiss keyboard
        view.endEditing(true)
        
        // Validation
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showAlert(title: "Missing Field", message: "Please enter your email address.")
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Missing Field", message: "Please enter your password.")
            return
        }
        
        // Show loading state
        loginButton.isEnabled = false
        loginButton.configuration?.showsActivityIndicator = true

        let details = ["email": email, "password": password]

        // Firebase login
        FirebaseManager.shared.loginUser(details: details) { [weak self] result in
            DispatchQueue.main.async {
                self?.loginButton.isEnabled = true
                self?.loginButton.configuration?.showsActivityIndicator = false
                
                switch result {
                case .success(let user):
                    print("Successfully logged in: \(user.uid)")
                    // Persist first name from displayName (e.g. "John Doe" → "John") so Home screen shows it
                    if let displayName = user.displayName, !displayName.isEmpty {
                        let firstName = displayName.components(separatedBy: " ").first ?? displayName
                        UserDefaults.standard.set(firstName, forKey: "user_first_name")
                    } else {
                        // Fallback: derive a name from the email prefix
                        let emailPrefix = email.components(separatedBy: "@").first ?? ""
                        let firstName = emailPrefix.components(separatedBy: ".").first?.capitalized ?? emailPrefix
                        if !firstName.isEmpty {
                            UserDefaults.standard.set(firstName, forKey: "user_first_name")
                        }
                    }
                    self?.performSegue(withIdentifier: "loginToHome", sender: self)
                    
                case .failure(let error):
                    self?.showAlert(title: "Sign In Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Reset Password",
            message: "Enter your email address and we'll send you a password reset link.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Email address"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send Reset Link", style: .default) { [weak self] _ in
            guard let email = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !email.isEmpty else {
                self?.showAlert(title: "Error", message: "Please enter a valid email address.")
                return
            }
            
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        self?.showAlert(title: "Email Sent", message: "Check your inbox for the password reset link.")
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Keyboard Handling
extension LoginViewController {
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
