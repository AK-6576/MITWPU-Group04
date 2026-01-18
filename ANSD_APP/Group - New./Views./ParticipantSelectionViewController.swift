//
//  ParticipantSelectionViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 01/12/25.
//

import UIKit

class ParticipantSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    let contacts: [Contact] = [
        Contact(name: "Steve Parker", imageName: "avatar_1"),
        Contact(name: "Amanda Waller", imageName: "avatar_2"),
        Contact(name: "Peter Parker", imageName: "avatar_3"),
        Contact(name: "Bruce Banner", imageName: "avatar_4"),
        Contact(name: "Sam Wilson", imageName: "avatar_5"),
        Contact(name: "Alex Ross", imageName: "avatar_6")
    ]
    
    var unavailableContacts: Set<String> = []
    var selectedIndices: Set<Int> = []
    var onPeopleAdded: (([String]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        if onPeopleAdded != nil {
            self.title = "Add Participants"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeTapped))
        } else {
            self.title = "Connect"
        }
    }
    
    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneTapped(_ sender: Any) {
        if let callback = onPeopleAdded {
            let selectedNames = selectedIndices.map { contacts[$0].name }
            callback(selectedNames)
            self.dismiss(animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "goToChat", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat" {
            if let chatVC = segue.destination as? GroupNewViewController {
                chatVC.modalPresentationStyle = .fullScreen
            }
        }
    }

    // MARK: - TableView Data Source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        
        let contact = contacts[indexPath.row]

        cell.nameLabel.text = contact.name
        
        if let image = UIImage(named: contact.imageName) {
            cell.profileImageView.image = image
        } else {
            cell.profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        if unavailableContacts.contains(contact.name) {
            cell.nameLabel.textColor = .systemGray3
            cell.isUserInteractionEnabled = false
            cell.accessoryType = .none
            cell.nameLabel.text = "\(contact.name) (Unavailable)"
            cell.profileImageView.alpha = 0.5
        } else {
            cell.isUserInteractionEnabled = true
            cell.profileImageView.alpha = 1.0
            if selectedIndices.contains(indexPath.row) {
                cell.nameLabel.textColor = .systemBlue
                cell.accessoryType = .checkmark
            } else {
                cell.nameLabel.textColor = .label
                cell.accessoryType = .none
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedIndices.contains(indexPath.row) {
            selectedIndices.remove(indexPath.row)
        } else {
            selectedIndices.insert(indexPath.row)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
