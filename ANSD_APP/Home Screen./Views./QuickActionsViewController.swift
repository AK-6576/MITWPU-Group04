//
//  QuickActionsViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 16/12/25.
//

import UIKit

class QuickActionsViewController: UITableViewController {

    // 1. DATA SOURCE
    var actionsList: [RoutineConversation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load data
        actionsList = QuickActionsRepository.getAllActions()
        
        // Setup Nav
        title = "Quick Actions"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton))
        
        // Remove empty header space
        tableView.tableHeaderView = UIView()
    }
    
    @objc func didTapAddButton() {
        print("Add button tapped")
    }

    // MARK: - TABLE VIEW CONFIGURATION

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionsList.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // ★ CRITICAL FIX: Cast the cell as QuickActionCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuickActionCell", for: indexPath) as? QuickActionCell else {
            return UITableViewCell()
        }
        
        let item = actionsList[indexPath.row]
        
        // ★ CALL CONFIGURE
        // This triggers the logic in the other file (Colors, Icons, etc.)
        cell.configure(with: item)
        
        // Handle (i) button tap
        cell.onInfoTapped = { [weak self] in
            self?.showActionDetails(for: item)
        }
        
        return cell
    }
    
    // Helper to show popup
    func showActionDetails(for item: RoutineConversation) {
        let message = item.description ?? "Status: \(item.status)"
        let alert = UIAlertController(title: item.conversationTopic, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
