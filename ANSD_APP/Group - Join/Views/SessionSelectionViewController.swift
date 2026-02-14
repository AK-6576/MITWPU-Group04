//
//  SessionSelectionViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 01/12/25.
//

import UIKit

class SessionSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var GroupJoinTableView: UITableView!
    
    let sessions: [GroupJoinSessions] = [
        GroupJoinSessions(title: "UI/UX Design Session", subtitle: "Reed Richards"),
        GroupJoinSessions(title: "Project Alpha X7", subtitle: "Bruce Wayne"),
        GroupJoinSessions(title: "Starbucks Meetup", subtitle: "Andrew Garfield"),
        GroupJoinSessions(title: "Assignment Completion", subtitle: "Peter Parker")
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
                // Pass the session data forward
                if let sessionData = sender as? GroupJoinSessions {
                    chatVC.title = sessionData.title
                }
            }
        }
    }
    
    // MARK: - TableView Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGroupedBackground
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let session = sessions[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = session.title
        content.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        content.secondaryText = session.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSession = sessions[indexPath.row]
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        showJoinSessionAlert(for: selectedSession)
    }
    
    // MARK: - Alert Logic
    func showJoinSessionAlert(for session: GroupJoinSessions) {
        let alert = UIAlertController(
            title: "Join Session",
            message: "Enter the Room Code shared with you",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "4-Digit Code"
            textField.textAlignment = .center
            textField.keyboardType = .numberPad
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let joinAction = UIAlertAction(title: "Join", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "goToChat", sender: session)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(joinAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}
