//
//  QuickActionsViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 16/12/25.
//

import UIKit

class QuickActionsViewController: UITableViewController {
    var actionsList: [RoutineConversation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        actionsList = QuickActionsRepository.getAllActions()
        tableView.tableHeaderView = UIView()
    }
    
    @objc func didTapAddButton() {
        print("Add button tapped")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionsList.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuickActionCell", for: indexPath) as? QuickActionCell else {
            return UITableViewCell()
        }
        
        let item = actionsList[indexPath.row]
        cell.configure(with: item)
        
        cell.onInfoTapped = { [weak self] in
            self?.showActionDetails(for: item)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = self.actionsList[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            self.actionsList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (action, view, completionHandler) in
            self?.showRenameAlert(for: item, index: indexPath.row)
            completionHandler(true)
        }
        renameAction.backgroundColor = .systemOrange
        renameAction.image = UIImage(systemName: "pencil")
        
        let infoAction = UIContextualAction(style: .normal, title: "Info") { [weak self] (action, view, completionHandler) in
            self?.showActionDetails(for: item)
            completionHandler(true)
        }
        infoAction.backgroundColor = .systemBlue
        infoAction.image = UIImage(systemName: "info.circle")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, renameAction, infoAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    func showActionDetails(for item: RoutineConversation) {
        let message = item.description ?? "Status: \(item.status)"
        let alert = UIAlertController(title: item.conversationTopic, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showRenameAlert(for item: RoutineConversation, index: Int) {
        let alert = UIAlertController(title: "Rename Action", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = item.conversationTopic
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            var updatedItem = item
            updatedItem.conversationTopic = newName
            self.actionsList[index] = updatedItem
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
