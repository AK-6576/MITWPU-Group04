//
//  ParticipantSelectionViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 01/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import Contacts
import MessageUI

class ParticipantSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var realContacts: [CNContact] = []
    var unavailableContacts: Set<String> = []
    var selectedIndices: Set<Int> = []
    var onPeopleAdded: (([String]) -> Void)?
    
    // The code you want to send
    let roomCode = "4492"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        setupNavigationBar()
        fetchRealContacts()
    }
    
    // MARK: - Contacts Fetching
    func fetchRealContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            guard let self = self else { return }
            
            if granted {
                // 2. Add 'CNContactPhoneNumbersKey' to the fetch request
                let keys = [
                    CNContactGivenNameKey,
                    CNContactFamilyNameKey,
                    CNContactThumbnailImageDataKey,
                    CNContactImageDataAvailableKey,
                    CNContactPhoneNumbersKey
                ] as [CNKeyDescriptor]
                
                let request = CNContactFetchRequest(keysToFetch: keys)
                
                do {
                    var newContacts: [CNContact] = []
                    try store.enumerateContacts(with: request) { (contact, stop) in
                        // Only add contacts that actually have a phone number
                        if !contact.phoneNumbers.isEmpty {
                            newContacts.append(contact)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.realContacts = newContacts
                        self.tableView.reloadData()
                    }
                } catch {
                    print("Error fetching contacts: \(error)")
                }
            }
        }
    }
    
    // MARK: - Navigation
    func setupNavigationBar() {
        if onPeopleAdded != nil {
            self.title = "Invite Participants"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeTapped))
        } else {
            self.title = "Connect"
        }
    }
    
    @objc func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Done Action (Trigger SMS)
    @IBAction func doneTapped(_ sender: Any) {
        
        // 1. Collect Phone Numbers from selected indices
        var recipients: [String] = []
        var selectedNames: [String] = []
        
        for index in selectedIndices {
            let contact = realContacts[index]
            let fullName = "\(contact.givenName) \(contact.familyName)"
            selectedNames.append(fullName)
            
            // Get the first phone number available
            if let firstNumber = contact.phoneNumbers.first?.value.stringValue {
                recipients.append(firstNumber)
            }
        }
        
        // 2. Check if we can send texts
        if MFMessageComposeViewController.canSendText() {
            let messageVC = MFMessageComposeViewController()
            messageVC.messageComposeDelegate = self
            messageVC.recipients = recipients
            messageVC.body = "Join my conversation room! The access code is: \(roomCode)"
            
            self.present(messageVC, animated: true, completion: nil)
        } else {
            // Fallback for Simulator or devices without SIM
            print("SMS services are not available on this device.")
            
            // If on Simulator, just proceed with the callback logic
            finishSelection(names: selectedNames)
        }
    }
    
    // MARK: - Message Composer Delegate
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        // Dismiss the SMS view first
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // Handle the result (Sent, Cancelled, Failed)
            switch result {
            case .sent:
                print("Invites sent!")
                // Once sent, we can close the selection screen and pass data back
                let selectedNames = self.selectedIndices.map {
                    "\(self.realContacts[$0].givenName) \(self.realContacts[$0].familyName)"
                }
                self.finishSelection(names: selectedNames)
                
            case .cancelled:
                print("User cancelled sending SMS.")
                // Do not dismiss the selection screen; let them try again
                
            case .failed:
                print("SMS failed.")
                
            @unknown default:
                break
            }
        }
    }
    
    func finishSelection(names: [String]) {
        if let callback = onPeopleAdded {
            callback(names)
            self.dismiss(animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "goToChat", sender: self)
        }
    }

    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return realContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        let contact = realContacts[indexPath.row]
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)

        cell.nameLabel.text = fullName
        
        if contact.imageDataAvailable, let data = contact.thumbnailImageData {
            cell.profileImageView.image = UIImage(data: data)
        } else {
            cell.profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        if unavailableContacts.contains(fullName) {
            cell.nameLabel.textColor = .systemGray3
            cell.isUserInteractionEnabled = false
            cell.accessoryType = .none
            cell.nameLabel.text = "\(fullName) (Unavailable)"
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
