//
//  SignUpViewController.swift
//  Group_4-ANSD_App
//
//  Created by Daiwiik on 13/12/25.
//

import UIKit

class SignUpViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SignUpCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let formFields = [
        "Full Name",
        "Email",
        "Birth of Date",
        "Phone Number",
        "Set Password",
        "Hearing Impairment Level"
    ]
    
    var userAnswers = Array(repeating: "", count: 6)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 2. Table Setup
        tableView.delegate = self
        tableView.dataSource = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SignUpCell", for: indexPath) as? SignUpTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(title: formFields[indexPath.row],
                       placeholder: "Enter \(formFields[indexPath.row])",
                       index: indexPath.row)
        
        cell.delegate = self
        return cell
    }
    
    // MARK: - Custom Delegate (Saving Data)
    func didUpdateInput(text: String, rowIndex: Int) {
        userAnswers[rowIndex] = text
        print("Data Updated: \(userAnswers)")
    }
}
