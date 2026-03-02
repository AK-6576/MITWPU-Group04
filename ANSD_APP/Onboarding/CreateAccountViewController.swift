//
//  CreateAccountViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj on 19/02/26.
//

import UIKit
import FirebaseAuth

class CreateAccountViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    @IBOutlet weak var continueButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
    }

    private func setupUI() {
        // Round the continue button for that sleek Echowave look
        continueButton.layer.cornerRadius = 28
        continueButton.clipsToBounds = true
        
        // Upgrade the text fields to look modern and soft
        let textFields = [firstNameTextField, lastNameTextField, emailTextField, passwordTextField, confirmPasswordTextField, phoneTextField]
        
        for field in textFields {
            // Check if the field is connected to avoid crashes
            guard let field = field else { continue }
            
            field.layer.cornerRadius = 12
            field.backgroundColor = .systemGray6
            field.borderStyle = .none
            
            // Add a little breathing room inside the text boxes
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: field.frame.height))
            field.leftView = paddingView
            field.leftViewMode = .always
        }
    }
    
    @IBAction func continueTapped(_ sender: UIButton) {
        // 1. Validate Password Match
        guard let password = passwordTextField.text,
              let confirmPassword = confirmPasswordTextField.text,
              password == confirmPassword else {
            print("Passwords do not match") // Replace with an Alert UI
            return
        }

        // 2. Package the data
        let userDetails = [
            "firstName": firstNameTextField.text ?? "",
            "lastName": lastNameTextField.text ?? "",
            "email": emailTextField.text ?? "",
            "password": password,
            "phone": phoneTextField.text ?? ""
        ]

        // 3. Call the FirebaseManager
        FirebaseManager.shared.createAccount(details: userDetails) { result in
            switch result {
            case .success(let user):
                print("Successfully registered: \(user.uid)")
                self.performSegue(withIdentifier: "createToHome", sender: self)
                
            case .failure(let error):
                print("Registration failed: \(error.localizedDescription)")
                
                // ADD THIS: Show the user (and yourself) exactly what went wrong
                let alert = UIAlertController(title: "Registration Error",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}

// MARK: - Keyboard Handling
extension CreateAccountViewController {
    private func setupKeyboardDismiss() {
        // This allows the user to tap anywhere on the scroll view to dismiss the keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
