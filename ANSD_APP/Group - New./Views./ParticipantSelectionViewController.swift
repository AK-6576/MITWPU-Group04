//
//  ParticipantSelectionViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 01/12/25.
//

import UIKit

class ParticipantSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Data
    let contacts = [
        "Steve Rogers", "Bucky Barnes", "Tony Stark",
        "Natasha Romanoff", "Bruce Banner", "Peter Parker",
        "Wanda Maximoff", "Vision"
    ]
    
    var unavailableContacts: Set<String> = []
    var selectedIndices: Set<Int> = []
    var onPeopleAdded: (([String]) -> Void)?
    
    // MARK: - Lifecycle
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
        }
        
        else {
            self.title = "Connect"
        }
    }
    
    // MARK: - Actions
    
    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneTapped(_ sender: Any) {
        if let callback = onPeopleAdded {
            let selectedNames = selectedIndices.map { contacts[$0] }
            callback(selectedNames)
            self.dismiss(animated: true, completion: nil)
        }
        
        else {
            performSegue(withIdentifier: "goToChat", sender: self)
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat" {
            if let chatVC = segue.destination as? GroupNewViewController {
                chatVC.modalPresentationStyle = .fullScreen
            }
        }
    }

    // MARK: - TableView Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let name = contacts[indexPath.row]
        
        cell.textLabel?.text = name
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        if unavailableContacts.contains(name) {
            cell.textLabel?.textColor = .systemGray3
            cell.isUserInteractionEnabled = false
            cell.accessoryType = .none
            cell.textLabel?.text = "\(name) (Unavailable)"
        } else {
            cell.isUserInteractionEnabled = true
            if selectedIndices.contains(indexPath.row) {
                cell.textLabel?.textColor = .systemBlue
                cell.accessoryType = .checkmark
            } else {
                cell.textLabel?.textColor = .label
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
