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
        // Do any additional setup after loading the view.
    }
    
    func setupUI() {
            // Just in case you didn't use the Runtime Attributes in Storyboard
            logoImageView.layer.cornerRadius = 30
            logoImageView.clipsToBounds = true
            
            // Ensure the button has the nice rounded look if not using "Capsule" style
            // getStartedButton.layer.cornerRadius = 12
            // getStartedButton.layer.masksToBounds = true
        }

        @IBAction func getStartedTapped(_ sender: UIButton) {
            print("Navigate to Sign Up")
        }
        
        @IBAction func loginTapped(_ sender: UIButton) {
            print("Navigate to Login")
        }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
