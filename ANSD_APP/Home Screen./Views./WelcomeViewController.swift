//
//  WelcomeViewController.swift
//  Group_4-ANSD_App
//
//  Created by Daiwiik on 13/12/25.
//

import UIKit

class WelcomeViewController: UIViewController {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var getStartedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        logoImageView.layer.cornerRadius = 30
        logoImageView.clipsToBounds = true
    }

    @IBAction func getStartedTapped(_ sender: UIButton) {
        print("Navigate to Sign Up")
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        print("Navigate to Login")
    }
}
