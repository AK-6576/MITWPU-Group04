//
//  WelcomeViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 19/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

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
        
        if let googleIcon = UIImage(named: "google_icon")?.withRenderingMode(.alwaysOriginal) {
            googleSignInButton.setImage(googleIcon, for: .normal)
        }

        googleSignInButton.configuration?.imagePadding = 10
        googleSignInButton.imageView?.contentMode = .scaleAspectFit
        
        createAccountButton.layer.cornerRadius = 28
        createAccountButton.layer.borderWidth = 1
        createAccountButton.layer.borderColor = UIColor.systemGray4.cgColor
        
        loginButton.layer.cornerRadius = 28
        loginButton.layer.borderWidth = 1
        loginButton.layer.borderColor = UIColor.systemGray4.cgColor
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
