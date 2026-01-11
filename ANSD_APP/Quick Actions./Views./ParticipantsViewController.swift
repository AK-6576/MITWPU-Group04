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
    @objc func doneTapped() {

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
        
        cell.textLabel?.text = "\(contact.givenName) \(contact.familyName)"
        
        let isSelected = selectedContactIDs.contains(contact.identifier)
        cell.accessoryType = isSelected ? .checkmark : .none
        
        cell.tintColor = .systemBlue
        
        return cell
    }

    // MARK: - TableView Delegate
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
