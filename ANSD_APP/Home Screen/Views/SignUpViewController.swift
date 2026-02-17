//
//  SignUpViewController.swift
//  Group_4-ANSD_App
//
//  Created by Daiwiik on 13/12/25.
//

import UIKit

class SignUpViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SignUpCellDelegate, HearingCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let formFields = ["Full Name", "Email", "Password" ,"Date of Birth", "Phone Number"]
    var userAnswers: [String: Any] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        // Hide keyboard on tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() { view.endEditing(true) }

    // MARK: - Table Logic
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Section 0: Text Fields, Section 1: Hearing Slider
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? formFields.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // Standard Inputs
            let cell = tableView.dequeueReusableCell(withIdentifier: "SignUpCell", for: indexPath) as! SignUpTableViewCell
            cell.configure(title: formFields[indexPath.row], placeholder: "Enter", index: indexPath.row)
            cell.delegate = self
            return cell
        } else {
            // Slider Input
            let cell = tableView.dequeueReusableCell(withIdentifier: "HearingCell", for: indexPath) as! HearingCell
            cell.delegate = self
            return cell
        }
    }
    
    // MARK: - Data Capture
    func didUpdateInput(text: String, rowIndex: Int) {
        let key = formFields[rowIndex]
        userAnswers[key] = text
    }
    
    func didUpdateHearingLevel(value: Float) {
        let level = value == 0 ? "Mild" : (value == 1 ? "Moderate" : "Severe")
        userAnswers["Hearing"] = level
        print("Updated Data: \(userAnswers)")
    }
}
