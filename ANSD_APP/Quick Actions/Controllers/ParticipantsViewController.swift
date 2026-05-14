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
    func didSelectParticipants(_ contacts: [CNContact])
}

class ParticipantsViewController: UITableViewController, UISearchResultsUpdating {

    // MARK: - Contact Picker Mode Variables
    weak var delegate: ParticipantsSelectionDelegate?

    var contacts = [CNContact]()

    var selectedContactIDs: Set<String> = []

    // Changing this to hold contacts to match initially selected names
    var initialSelectedContacts: [CNContact] = []

    var filteredContacts = [CNContact]()
    let searchController = UISearchController(searchResultsController: nil)
    var isFiltering: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }

    // MARK: - Viewer Mode Variables
    /// Set to `true` to switch from "contact picker" to "session participants viewer"
    var viewerMode: Bool = false

    /// The names of all participants invited to this Quick Action
    var viewerParticipantNames: [String] = []

    /// The room code for observing Firebase presence
    var viewerRoomCode: String?

    /// Stores real-time set of online (sanitized) user names from Firebase
    private var onlineNames: Set<String> = []

    private let firebase = FirebaseManager.shared

    // MARK: - Lifecycle

    // Function - Initializes the view lifecycle, setting up navigation buttons, registering cells, and triggering the contact fetch.
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        if viewerMode {
            setupViewerMode()
        } else {
            setupPickerMode()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if viewerMode, let code = viewerRoomCode {
            firebase.stopObservingPresence(roomCode: code)
        }
    }

    // MARK: - Picker Mode Setup (Original Logic)
    private func setupPickerMode() {
        title = "Add Participants"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Contacts"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        fetchContacts()
    }

    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let searchText = searchBar.text ?? ""
        filteredContacts = contacts.filter { contact in
            let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
            return fullName.contains(searchText.lowercased())
        }
        tableView.reloadData()
    }

    // MARK: - Viewer Mode Setup (New Logic)
    private func setupViewerMode() {
        title = "Session Participants"

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(cancelTapped))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ParticipantViewerCell")

        // Start observing Firebase presence
        if let code = viewerRoomCode {
            firebase.observePresence(roomCode: code) { [weak self] onlineSet in
                guard let self = self else { return }
                self.onlineNames = onlineSet
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }

        tableView.reloadData()
    }

    // MARK: - Logic: Fetch Contacts (Picker Mode Only)

    // Function - Requests authorization to access the user's contacts and retrieves them if granted.
    func fetchContacts() {
        let store = CNContactStore()

        store.requestAccess(for: .contacts) { [weak self] granted, _ in
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
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactIdentifierKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                var newContacts = [CNContact]()
                try store.enumerateContacts(with: request) { (contact, _) in
                    newContacts.append(contact)

                    let fullName = "\(contact.givenName) \(contact.familyName)"
                    if self.initialSelectedContacts.contains(where: { "\($0.givenName) \($0.familyName)" == fullName }) {
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

        delegate?.didSelectParticipants(selectedContacts)
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

    private var selectedContactsCurrent: [CNContact] {
        return contacts.filter { selectedContactIDs.contains($0.identifier) }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if viewerMode { return 1 }
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if viewerMode { return nil }
        if section == 0 {
            return selectedContactsCurrent.isEmpty ? nil : "Added Participants"
        } else {
            return "Contacts"
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewerMode {
            return viewerParticipantNames.count
        }
        if section == 0 {
            return selectedContactsCurrent.count
        }
        return isFiltering ? filteredContacts.count : contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewerMode {
            return configureViewerCell(for: indexPath)
        } else {
            return configurePickerCell(for: indexPath)
        }
    }

    // MARK: - Picker Cell (Original)
    private func configurePickerCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)

        let contact: CNContact
        if indexPath.section == 0 {
            contact = selectedContactsCurrent[indexPath.row]
        } else {
            contact = isFiltering ? filteredContacts[indexPath.row] : contacts[indexPath.row]
        }

        cell.textLabel?.text = "\(contact.givenName) \(contact.familyName)"

        let isSelected = selectedContactIDs.contains(contact.identifier)
        cell.accessoryType = isSelected ? .checkmark : .none

        cell.tintColor = .systemBlue

        return cell
    }

    // MARK: - Viewer Cell (New - with Green/Grey Dot)
    private func configureViewerCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantViewerCell", for: indexPath)
        let name = viewerParticipantNames[indexPath.row]

        cell.selectionStyle = .none
        cell.textLabel?.text = name
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        // Check if this name is online by matching against sanitized Firebase keys
        let sanitizedName = firebase.sanitizeKey(name)
        let isOnline = onlineNames.contains(sanitizedName)

        // Create the status dot
        let dotSize: CGFloat = 12
        let dotView = UIView(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
        dotView.layer.cornerRadius = dotSize / 2
        dotView.backgroundColor = isOnline ? .systemGreen : .systemGray3

        // Wrap in accessory view
        cell.accessoryView = dotView

        // Detail text for status
        cell.detailTextLabel?.text = isOnline ? "Online" : "Offline"
        cell.detailTextLabel?.textColor = isOnline ? .systemGreen : .secondaryLabel
        cell.detailTextLabel?.font = .systemFont(ofSize: 12)

        return cell
    }

    // MARK: - TableView Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewerMode {
            tableView.deselectRow(at: indexPath, animated: true)
            return // No action in viewer mode
        }

        tableView.deselectRow(at: indexPath, animated: true)

        let contact: CNContact
        if indexPath.section == 0 {
            contact = selectedContactsCurrent[indexPath.row]
        } else {
            contact = isFiltering ? filteredContacts[indexPath.row] : contacts[indexPath.row]
        }
        let id = contact.identifier

        if selectedContactIDs.contains(id) {
            selectedContactIDs.remove(id)
        } else {
            selectedContactIDs.insert(id)
        }

        tableView.reloadData()
    }

    // MARK: - Row Height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewerMode ? 56 : UITableView.automaticDimension
    }
}
