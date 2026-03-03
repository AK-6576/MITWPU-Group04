//
//  ParticipantsViewController.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 07/01/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//
import UIKit
import Contacts

protocol ParticipantsSelectionDelegate: AnyObject {
    func didSelectParticipants(_ names: [String])
}

class ParticipantsViewController: UITableViewController {
    
    // MARK: - Variables
    weak var delegate: ParticipantsSelectionDelegate?
    
    var contacts = [CNContact]()
    
    var selectedContactIDs: Set<String> = []
    
    var initialSelectedNames: [String] = []

    // MARK: - Lifecycle
    
    // Function - Initializes the view lifecycle, setting up navigation buttons, registering cells, and triggering the contact fetch.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Participants"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")
        
        fetchContacts()
    }

    // MARK: - Logic: Fetch Contacts
    
    // Function - Requests authorization to access the user's contacts and retrieves them if granted.
    func fetchContacts() {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            guard let self = self else { return }
            
            if granted {
                self.getContacts(from: store)
            } else {
                DispatchQueue.main.async {
                    self.showPermissionAlert()
                }
            }
        }
    }
    
    // Function - Fetches contact details from the store, matches them with initially selected names, and updates the table view.
    func getContacts(from store: CNContactStore) {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactIdentifierKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                var newContacts = [CNContact]()
                try store.enumerateContacts(with: request) { (contact, stop) in
                    newContacts.append(contact)

                    let fullName = "\(contact.givenName) \(contact.familyName)"
                    if self.initialSelectedNames.contains(fullName) {
                        self.selectedContactIDs.insert(contact.identifier)
                    }
                }

                self.contacts = newContacts

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.tableView.reloadData()
                }
            } catch {
                print("Failed to fetch contacts: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    // Function - Filters the contacts based on the user's selection, passes the names back to the delegate, and dismisses the view.
    @objc func doneTapped() {

        let selectedContacts = contacts.filter { selectedContactIDs.contains($0.identifier) }
        let names = selectedContacts.map { "\($0.givenName) \($0.familyName)" }
        
        delegate?.didSelectParticipants(names)
        dismiss(animated: true)
    }
    
    // Function - Dismisses the view controller without saving any changes.
    @objc func cancelTapped() {
        dismiss(animated: true)
    }
    
    // Function - Displays an alert informing the user that contact access is required and denied.
    func showPermissionAlert() {
        let alert = UIAlertController(title: "Permission Denied", message: "Please enable contacts access in Settings to invite friends.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - TableView Data Source
    
    // Function - Returns the total number of contacts available to display in the list.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    // Function - Dequeues and configures a cell for a contact, showing their name and a checkmark if selected.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let contact = contacts[indexPath.row]
        
        cell.textLabel?.text = "\(contact.givenName) \(contact.familyName)"
        
        let isSelected = selectedContactIDs.contains(contact.identifier)
        cell.accessoryType = isSelected ? .checkmark : .none
        
        cell.tintColor = .systemBlue
        
        return cell
    }

    // MARK: - TableView Delegate
    
    // Function - Handles row selection to toggle the checkmark state for a specific contact.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contact = contacts[indexPath.row]
        let id = contact.identifier
        
        if selectedContactIDs.contains(id) {
            selectedContactIDs.remove(id)
        } else {
            selectedContactIDs.insert(id)
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
