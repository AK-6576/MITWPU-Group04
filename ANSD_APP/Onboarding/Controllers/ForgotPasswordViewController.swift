//
//  ForgotPasswordViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 17/03/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import FirebaseAuth

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reset Password"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        setupUI()
        setupKeyboardDismiss()
        emailTextField.delegate = self
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Email field
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.returnKeyType = .send
        emailTextField.textContentType = .emailAddress
        emailTextField.placeholder = "your@email.com"
        emailTextField.layer.cornerRadius = 12
        emailTextField.backgroundColor = .systemGray6
        emailTextField.borderStyle = .none
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: emailTextField.frame.height))
        emailTextField.leftView = paddingView
        emailTextField.leftViewMode = .always

        // Status label
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.isHidden = true

        // Activity indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .medium
        activityIndicator.stopAnimating()
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        sendResetLinkTapped(sendButton)
        return true
    }

    // MARK: - Actions

    @IBAction func sendResetLinkTapped(_ sender: UIButton) {
        view.endEditing(true)

        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showStatus("Please enter your email address.", isError: true)
            shakeTextField()
            return
        }

        guard isValidEmail(email) else {
            showStatus("Please enter a valid email address.", isError: true)
            shakeTextField()
            return
        }

        setLoading(true)

        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.setLoading(false)

                if let error = error {
                    self.showStatus(error.localizedDescription, isError: true)
                } else {
                    self.showStatus("✓  Reset link sent! Check your inbox (and spam folder).", isError: false)
                    self.sendButton.isEnabled = false
                    self.emailTextField.isEnabled = false

                    // Auto-pop after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func setLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            sendButton.isEnabled = false
            sendButton.configuration?.showsActivityIndicator = true
        } else {
            activityIndicator.stopAnimating()
            sendButton.isEnabled = true
            sendButton.configuration?.showsActivityIndicator = false
        }
    }

    private func showStatus(_ message: String, isError: Bool) {
        statusLabel.text = message
        statusLabel.textColor = isError ? .systemRed : .systemGreen
        UIView.animate(withDuration: 0.25) {
            self.statusLabel.isHidden = false
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func shakeTextField() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, 0]
        emailTextField.layer.add(animation, forKey: "shake")
    }
}

// MARK: - Keyboard Handling

extension ForgotPasswordViewController {
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
