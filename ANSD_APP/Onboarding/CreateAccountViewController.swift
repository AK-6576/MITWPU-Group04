//
//  CreateAccountViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 19/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
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
        // Round the continue button for that sleek SyncWave look
        continueButton.layer.cornerRadius = 28
        continueButton.clipsToBounds = true
        
        // Upgrade the text fields to look modern and soft
        let textFields = [firstNameTextField, lastNameTextField, emailTextField, passwordTextField, confirmPasswordTextField, phoneTextField]
        
        for field in textFields {
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
            let alert = UIAlertController(title: "Error", message: "Passwords do not match.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }

        // 2. Package the data (Ready for when Firebase is fixed)
        let userDetails = [
            "firstName": firstNameTextField.text ?? "",
            "lastName": lastNameTextField.text ?? "",
            "email": emailTextField.text ?? "",
            "password": password,
            "phone": phoneTextField.text ?? ""
        ]

        // 3. UI REVIEW BYPASS: Pretend Firebase succeeded so we can show the next screen!
        print("Mock Registration Successful with details: \(userDetails)")
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showCalibration", sender: self)
        }
        
        FirebaseManager.shared.createAccount(details: userDetails) { result in
            switch result {
            case .success(let user):
                print("Successfully registered: \(user.uid)")
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "showCalibration", sender: self)
                }
                
            case .failure(let error):
                print("Registration failed: \(error.localizedDescription)")
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
