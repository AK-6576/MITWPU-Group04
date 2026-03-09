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
    var onParticipantsSelected: (([String]) -> Void)?
    
    // The code you want to send
    var roomCode = "4492"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Randomize Room ID if it's the static default
        if roomCode == "4492" {
            roomCode = String(format: "%04d", Int.random(in: 1000...9999))
        }
        
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
        if onParticipantsSelected != nil {
            self.title = "Invite Participants (\(roomCode))"
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
        
        var recipients: [String] = []
        var selectedNames: [String] = []
        
        for index in selectedIndices {
            let contact = realContacts[index]
            let fullName = "\(contact.givenName) \(contact.familyName)"
            selectedNames.append(fullName)
            
            if let firstNumber = contact.phoneNumbers.first?.value.stringValue {
                recipients.append(firstNumber)
            }
        }
        
        if recipients.isEmpty {
            // If no recipients, just proceed
            finishSelection(names: selectedNames)
            return
        }
        
        if MFMessageComposeViewController.canSendText() {
            let messageVC = MFMessageComposeViewController()
            messageVC.messageComposeDelegate = self
            messageVC.recipients = recipients
            messageVC.body = "Join my conversation room! The access code is: \(roomCode)"
            
            self.present(messageVC, animated: true, completion: nil)
        } else {
            // Show alert fallback for simulator/no SIM
            let alert = UIAlertController(title: "SMS Unavailable", message: "Your device cannot send SMS. Please share the Room Code: \(roomCode) manually with your participants.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                self?.finishSelection(names: selectedNames)
            }))
            self.present(alert, animated: true)
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
        if let callback = onParticipantsSelected {
            callback(names)
            self.dismiss(animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "goToChat", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat" {
            if let destVC = segue.destination as? GroupNewViewController {
                destVC.currentSessionID = self.roomCode
            }
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
