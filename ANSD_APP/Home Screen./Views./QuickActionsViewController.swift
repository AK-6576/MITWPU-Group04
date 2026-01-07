import UIKit

class QuickActionsViewController: UITableViewController {
    
    var actionsList: [RoutineConversation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        actionsList = QuickActionsRepository.getAllActions()
        
        // Cosmetic: remove empty cell lines at bottom
        tableView.tableHeaderView = UIView()
        
        // MARK: - FIX IS HERE
        // I removed the code that was adding the button manually.
        // Since you added the button in the Storyboard and connected the Segue,
        // you do NOT need to add it here in code.
    }
    
    // MARK: - Navigation (Segue)
    // 1. This function is called automatically when you tap the "+" button in Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // 2. Check if the destination is the correct controller
        if let addVC = segue.destination as? AddActionTableViewController {
            
            // 3. Set the delegate so we get the data back!
            addVC.delegate = self
        }
    }
    
    // MARK: - TableView Data Source
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
    
    // MARK: - Swipe Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = self.actionsList[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            self.actionsList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // TODO: Call your repository to delete permanently
            // QuickActionsRepository.delete(item)
            
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
    
    // MARK: - Helper Methods
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

// MARK: - AddActionDelegate Implementation
extension QuickActionsViewController: AddActionDelegate {
    
    func didCreateNewAction(_ action: RoutineConversation) {
        // 1. Add to the local data array
        actionsList.append(action)
        
        // 2. Refresh the table view to show the new row
        tableView.reloadData()
        
        // 3. (Optional) Save to DB here
    }
}
