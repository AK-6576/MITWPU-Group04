//
//  SessionSelectionViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 01/12/25.
//

import UIKit

class SessionSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var GroupJoinTableView: UITableView!
    
    // Mock Data: If you add "Doomsday Meeting" here, that title will now carry over.
    let sessions: [GroupJoinSessions] = [
        GroupJoinSessions(title: "Join via Code", subtitle: "Enter a Room Code."),

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
        
        // Fix for Top Gap (iOS 15+)
        if #available(iOS 15.0, *) {
            GroupJoinTableView.sectionHeaderTopPadding = 0
        }
        var frame = CGRect.zero
        frame.size.height = .leastNormalMagnitude
        GroupJoinTableView.tableHeaderView = UIView(frame: frame)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat" {
            if let chatVC = segue.destination as? GroupJoinViewController {
                chatVC.modalPresentationStyle = .fullScreen
                
                // Expecting sender to be a tuple: (code: String, title: String)
                if let data = sender as? (code: String, title: String) {
                    chatVC.currentSessionID = data.code
                    chatVC.sessionTitle = data.title // Pass the title forward
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
        content.textProperties.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedTitle = sessions[indexPath.row].title
        
        // Pass the selected title to the alert logic
        showJoinSessionAlert(title: selectedTitle)
    }
    
    // MARK: - Alert Logic
    func showJoinSessionAlert(title: String) {
        let alert = UIAlertController(
            title: "Join Session",
            message: "Enter the 4-Digit Room Code for '\(title)'",
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
            
            if let code = alert.textFields?.first?.text, !code.isEmpty {
                // Pass BOTH code and title
                let data = (code: code, title: title)
                self.performSegue(withIdentifier: "goToChat", sender: data)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(joinAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}
