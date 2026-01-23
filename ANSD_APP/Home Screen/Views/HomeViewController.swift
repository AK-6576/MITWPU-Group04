//
//  HomeViewController.swift
//  ANSD_APP
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    var quickActions: [QuickActionsConversation] = []
    var routineConversations: [QuickActionsConversation] = []
    
    // Function - Initializes the view lifecycle, configuring the table view and hiding the back button.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        navigationItem.hidesBackButton = true
    }
    
    // Function - Reloads the data whenever the view is about to appear on screen.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    // Function - Configures the table view's delegate, data source, and visual appearance settings.
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
    }

    // Function - Fetches active actions from the repository, categorizes them into lists, and reloads the table view.
    func loadData() {
        let allItems = QuickActionsRepository.shared.getAllActions().filter { $0.status != "Done" }

        self.routineConversations = Array(allItems.prefix(2))
        self.quickActions = Array(allItems.dropFirst(2))
        
        self.tableView.reloadData()
    }

    // MARK: - Actions (Profile / Footer Buttons)
    
    // Function - Action triggered by a tap gesture to navigate to the new conversation screen.
    @IBAction func didTapNewConversation(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showNewConversation", sender: self)
    }

    // Function - Action triggered by a tap gesture to navigate to the join conversation screen.
    @IBAction func didTapJoinConversation(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showJoinConversation", sender: self)
    }

    // Function - Action triggered by a tap gesture to navigate to the quick captioning screen.
    @IBAction func didTapQuickCaption(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "Test1", sender: self)
    }
    
    // MARK: - Navigation Preparation
    
    // Function - Prepares for segues by configuring destination view controllers with necessary data.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        
        if segue.identifier == "showProfile" {
            let _ = (segue.destination as? UINavigationController)?.viewControllers.first as? ProfileTableViewController ?? segue.destination as? ProfileTableViewController
        }
        else if segue.identifier == "viewConvoCell" {

            guard let destVC = segue.destination as? ChatHistory2ViewController,
                  let selectedItem = sender as? QuickActionsConversation else { return }
            
            if let fullData = DataManager.shared.getConversation(byId: selectedItem.id) {
                destVC.histconversationData = fullData
            } else {
                let fallbackConv = Conversation(
                    id: selectedItem.id,
                    title: selectedItem.conversationTopic,
                    messages: [],
                    participants: [],
                    notes: selectedItem.description ?? "",
                    startTime: selectedItem.startTime,
                    category: selectedItem.categoryTitle,
                    icon: selectedItem.iconName
                )
                destVC.histconversationData = fallbackConv
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Function - Displays an alert allowing the user to rename a specific quick action and saves the changes.
    private func showRenameAlert(for item: QuickActionsConversation, row: Int) {
        let alert = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = item.conversationTopic }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            var updatedItem = item
            updatedItem.conversationTopic = newName
            
            // Update Repo
            QuickActionsRepository.shared.updateAction(updatedItem)
            
            // Update Local
            self.quickActions[row] = updatedItem
            self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - TableView Delegate & DataSource
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    // Function - Returns the total number of sections in the table view.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    // Function - Returns the number of rows for the specified section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0) ? quickActions.count : routineConversations.count
    }
    
    // MARK: - Header Configuration
    
    // Function - Configures and returns the custom header view for each section.
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let cellID = (section == 0) ? "QAHeaderCell" : "VCHeaderCell"

        guard let header = tableView.dequeueReusableCell(withIdentifier: cellID) as? HeaderCells else {
            return nil
        }

        if section == 0 {
            header.titleLabel.text = "Quick Actions"
            header.subtitleLabel?.text = "Upcoming"
        } else {
            header.titleLabel.text = "View Conversations"
        }
        
        return header.contentView
    }
    
    // Function - Returns the height for the section header based on the section index.
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0) ? 70 : 50
    }
    
    // MARK: - Row Configuration
    
    // Function - Dequeues and configures the appropriate cell type for the given index path.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as? QuickActionsTableViewCell else { return UITableViewCell() }
            let item = quickActions[indexPath.row]
            let isLastRow = indexPath.row == quickActions.count - 1
            cell.configure(with: item, isLast: isLastRow)
            cell.onInfoTapped = { [weak self] in self?.presentInfoScreen(for: item) }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCardCell", for: indexPath) as? ConversationCardCell else { return UITableViewCell() }
            let item = routineConversations[indexPath.row]
            cell.configure(with: item)
            return cell
        }
    }
    
    // Function - Handles row selection to trigger specific segues based on the item category.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = (indexPath.section == 0) ? quickActions[indexPath.row] : routineConversations[indexPath.row]
        
        var segueID = ""
        if indexPath.section == 0 {
            switch item.categoryTitle {
            case "Office": segueID = "office"
            case "Family": segueID = "family"
            case "Friends": segueID = "friends"
            default: return
            }
        } else {
            segueID = "viewConvoCell"
        }
        performSegue(withIdentifier: segueID, sender: item)
    }
    
    // Function - Displays an alert containing details about the selected routine conversation.
    func presentInfoScreen(for item: QuickActionsConversation) {
        let alert = UIAlertController(title: item.conversationTopic, message: item.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Swipe Actions
    
    // Function - Configures swipe actions for deleting and renaming items, enabled only for the Quick Actions section.
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 0 else { return nil }
        
        let item = quickActions[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            // Delete from Repo
            QuickActionsRepository.shared.deleteAction(item)
            
            // Delete from Local Array
            self.quickActions.remove(at: indexPath.row)
            
            // Delete Row
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        let renameAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (_, _, completion) in
            self?.showRenameAlert(for: item, row: indexPath.row)
            completion(true)
        }
        renameAction.backgroundColor = .systemOrange
        renameAction.image = UIImage(systemName: "pencil")
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}
