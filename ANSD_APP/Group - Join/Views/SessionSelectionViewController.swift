//
//  SessionSelectionViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 01/12/25.
//

import UIKit

class SessionSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var GroupJoinTableView: UITableView!
    
    // Mock Data for "Recent Sessions" or "Available Rooms"
    // In a real app, you might fetch this from Firebase or keep it static
    let sessions: [GroupJoinSessions] = [
        GroupJoinSessions(title: "Join via Code", subtitle: "Enter a Room Code.")
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    func setupTableView() {
        GroupJoinTableView.delegate = self
        GroupJoinTableView.dataSource = self
        GroupJoinTableView.backgroundColor = .systemGroupedBackground
        GroupJoinTableView.tableFooterView = UIView()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat" {
            if let chatVC = segue.destination as? GroupJoinViewController {
                chatVC.modalPresentationStyle = .fullScreen
                
                // Pass the code entered by the user
                if let code = sender as? String {
                    chatVC.currentSessionID = code
                }
            }
        }
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SessionCell")
        let session = sessions[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = session.title
        content.secondaryText = session.subtitle
        
        // Font Styling
        content.textProperties.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Trigger the Single Input Alert
        showJoinSessionAlert()
    }
    
    // MARK: - Alert Logic (The Only Input Screen)
    func showJoinSessionAlert() {
        let alert = UIAlertController(
            title: "Join Session",
            message: "Enter the 4-Digit Room Code",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Room Code"
            textField.textAlignment = .center
            textField.keyboardType = .numberPad
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let joinAction = UIAlertAction(title: "Join", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Get the code
            if let code = alert.textFields?.first?.text, !code.isEmpty {
                // Perform Segue and pass the code
                self.performSegue(withIdentifier: "goToChat", sender: code)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(joinAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}
