//
//  ParticipantSelectionViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 01/12/25.
//

import UIKit
import Contacts // 1. Import the framework

class ParticipantSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    // 2. Data Source: Use CNContact instead of a custom struct
    var contacts: [CNContact] = []
    let contactStore = CNContactStore()
    
    // Keep this for your logic (matches by full name string)
    var unavailableContacts: Set<String> = []
    var selectedIndices: Set<Int> = []
    var onPeopleAdded: (([String]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        setupNavigationBar()
        
        // 3. Fetch contacts when view loads
        fetchContacts()
    }
    
    func setupNavigationBar() {
        if onPeopleAdded != nil {
            self.title = "Add Participants"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeTapped))
        } else {
            self.title = "Connect"
        }
    }
    
    // MARK: - Contacts Framework Logic
    
    func fetchContacts() {
        // 4. Request Access
        contactStore.requestAccess(for: .contacts) { [weak self] (granted, error) in
            guard let self = self else { return }
            
            if granted {
                self.retrieveContactsFromStore()
            } else {
                DispatchQueue.main.async {
                    self.showSettingsAlert()
                }
            }
        }
    }
    
    func retrieveContactsFromStore() {
        // 5. Define the keys we want to fetch (Name and Image)
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactThumbnailImageDataKey,
            CNContactImageDataAvailableKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        // Sort by given name
        request.sortOrder = .userDefault
        
        var fetchedContacts: [CNContact] = []
        
        do {
            try contactStore.enumerateContacts(with: request) { (contact, stop) in
                fetchedContacts.append(contact)
            }
            
            // 6. Update UI on Main Thread
            DispatchQueue.main.async {
                self.contacts = fetchedContacts
                self.tableView.reloadData()
            }
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
    }
    
    func showSettingsAlert() {
        let alert = UIAlertController(title: "Permission Denied", message: "Please enable Contacts access in Settings to invite friends.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        self.present(alert, animated: true)
    }
    
    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneTapped(_ sender: Any) {
        if let callback = onPeopleAdded {
            // Map selected contacts to their Full Name strings
            let selectedNames = selectedIndices.map { index -> String in
                let contact = contacts[index]
                return "\(contact.givenName) \(contact.familyName)"
            }
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
        let fullName = "\(contact.givenName) \(contact.familyName)"
        
        // Configure Name
        cell.nameLabel.text = fullName
        
        // Configure Image (Check if real contact has image data)
        if contact.imageDataAvailable, let data = contact.thumbnailImageData {
            cell.profileImageView.image = UIImage(data: data)
            // Ensure circular style is applied here or in Cell awakeFromNib
            cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.height / 2
            cell.profileImageView.clipsToBounds = true
            cell.profileImageView.contentMode = .scaleAspectFill
        } else {
            cell.profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        // Handle Unavailable State
        if unavailableContacts.contains(fullName) {
            cell.nameLabel.textColor = .systemGray3
            cell.isUserInteractionEnabled = false
            cell.accessoryType = .none
            cell.nameLabel.text = "\(fullName) (Unavailable)"
            cell.profileImageView.alpha = 0.5
        } else {
            cell.isUserInteractionEnabled = true
            cell.profileImageView.alpha = 1.0
            
            // Handle Selection State
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
