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
        // Logic to add new item goes here
    }

    // MARK: - TABLE VIEW CONFIGURATION

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionsList.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Cast the cell as QuickActionCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuickActionCell", for: indexPath) as? QuickActionCell else {
            return UITableViewCell()
        }
        
        let item = actionsList[indexPath.row]
        
        // Configure cell
        cell.configure(with: item)
        
        // Handle (i) button tap (Optional, since we now have swipe)
        cell.onInfoTapped = { [weak self] in
            self?.showActionDetails(for: item)
        }
        
        return cell
    }
    
    // MARK: - SWIPE ACTIONS (Delete, Rename, Info)
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let item = self.actionsList[indexPath.row]
        
        // 1. DELETE ACTION
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            // Remove from data source
            self.actionsList.remove(at: indexPath.row)
            // Remove from TableView
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // TODO: Call your Repository to delete from persistent storage here
            // QuickActionsRepository.deleteAction(item)
            
            completionHandler(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        // 2. RENAME ACTION
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (action, view, completionHandler) in
            self?.showRenameAlert(for: item, index: indexPath.row)
            completionHandler(true)
        }
        renameAction.backgroundColor = .systemOrange
        renameAction.image = UIImage(systemName: "pencil")
        
        // 3. INFO ACTION
        let infoAction = UIContextualAction(style: .normal, title: "Info") { [weak self] (action, view, completionHandler) in
            self?.showActionDetails(for: item)
            completionHandler(true)
        }
        infoAction.backgroundColor = .systemBlue
        infoAction.image = UIImage(systemName: "info.circle")
        
        // Combine actions (Order: Right to Left)
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, renameAction, infoAction])
        configuration.performsFirstActionWithFullSwipe = false // Prevent accidental deletes
        
        return configuration
    }
    
    // MARK: - HELPERS
    
    // Helper to show details popup
    func showActionDetails(for item: RoutineConversation) {
        let message = item.description ?? "Status: \(item.status)"
        let alert = UIAlertController(title: item.conversationTopic, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Helper to rename
    func showRenameAlert(for item: RoutineConversation, index: Int) {
        let alert = UIAlertController(title: "Rename Action", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = item.conversationTopic
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            // Update Data Source
            // Assuming `conversationTopic` is a var in your model
            // If it's a struct (value type), we might need to update the array directly
            var updatedItem = item
            updatedItem.conversationTopic = newName
            self.actionsList[index] = updatedItem
            
            // Reload Row
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            
            // TODO: Save changes to Repository
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
