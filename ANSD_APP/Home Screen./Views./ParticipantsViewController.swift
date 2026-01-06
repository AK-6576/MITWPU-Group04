import UIKit
import Contacts // 1. Import the framework

protocol ParticipantsSelectionDelegate: AnyObject {
    func didSelectParticipants(_ names: [String])
}

class ParticipantsViewController: UITableViewController {
    
    // MARK: - Variables
    weak var delegate: ParticipantsSelectionDelegate?
    
    // Store real contact objects here
    var contacts = [CNContact]()
    
    // We use IDs for selection to handle people with the same name correctly
    var selectedContactIDs: Set<String> = []
    
    // Pass pre-selected names back to check them initially (Optional logic)
    var initialSelectedNames: [String] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Participants"
        view.backgroundColor = .systemBackground
        
        // Navigation Setup
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        
        // Register Cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")
        
        // Fetch Contacts immediately
        fetchContacts()
    }

    // MARK: - Logic: Fetch Contacts
    func fetchContacts() {
        let store = CNContactStore()
        
        // Request Permission
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            guard let self = self else { return }
            
            if granted {
                // Permission granted, fetch data
                self.getContacts(from: store)
            } else {
                // Permission denied
                DispatchQueue.main.async {
                    self.showPermissionAlert()
                }
            }
        }
    }
    
    func getContacts(from store: CNContactStore) {
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactIdentifierKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .userDefault
            
            do {
                var newContacts = [CNContact]()
                try store.enumerateContacts(with: request) { (contact, stop) in
                    newContacts.append(contact)
                    
                    // --- NEW CODE START: Check if this person was previously selected ---
                    let fullName = "\(contact.givenName) \(contact.familyName)"
                    if self.initialSelectedNames.contains(fullName) {
                        self.selectedContactIDs.insert(contact.identifier)
                    }
                    // --- NEW CODE END ---
                }
                
                self.contacts = newContacts
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("Failed to fetch contacts: \(error)")
            }
        }

    // MARK: - Actions
    @objc func doneTapped() {
        // Map the selected IDs back to Names to send to the delegate
        let selectedContacts = contacts.filter { selectedContactIDs.contains($0.identifier) }
        let names = selectedContacts.map { "\($0.givenName) \($0.familyName)" }
        
        delegate?.didSelectParticipants(names)
        dismiss(animated: true)
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true)
    }
    
    func showPermissionAlert() {
        let alert = UIAlertController(title: "Permission Denied", message: "Please enable contacts access in Settings to invite friends.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - TableView Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let contact = contacts[indexPath.row]
        
        // Format Name
        cell.textLabel?.text = "\(contact.givenName) \(contact.familyName)"
        
        // Handle Selection State
        let isSelected = selectedContactIDs.contains(contact.identifier)
        cell.accessoryType = isSelected ? .checkmark : .none
        
        // Optional: Add simple styling
        cell.tintColor = .systemBlue
        
        return cell
    }

    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contact = contacts[indexPath.row]
        let id = contact.identifier
        
        // Toggle Selection
        if selectedContactIDs.contains(id) {
            selectedContactIDs.remove(id)
        } else {
            selectedContactIDs.insert(id)
        }
        
        // Reload row for smooth animation
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
