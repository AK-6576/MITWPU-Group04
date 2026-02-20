//
//  CreateAccountViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj on 19/02/26.
//

import UIKit

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
    
    // MARK: - Actions
    @IBAction func continueTapped(_ sender: UIButton) {
        print("Continue tapped! Moving to the next screen.")
        // We will add the navigation code here next!
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
