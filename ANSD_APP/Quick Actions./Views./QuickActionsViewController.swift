//
//  QuickActionsViewController.swift
//  ANSD_APP
//

import UIKit

// View controller managing quick action routines organized by category
class QuickActionsViewController: UITableViewController, SectionHeaderDelegate {
    
    var sections: [RoutineSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Quick Actions"
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.identifier)
        tableView.tableHeaderView = UIView()
    }
    
    // Refreshes data when view appears to ensure latest changes are displayed
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    // Loads and filters active actions from the repository
    private func loadData() {
        let allSections = QuickActionsRepository.shared.getGroupedSections()
        
        self.sections = allSections.compactMap { section in
            let activeItems = section.items.filter { $0.status != "Done" }
            
            if activeItems.isEmpty {
                return nil
            }
            
            var filteredSection = section
            filteredSection.items = activeItems
            return filteredSection
        }
        
        tableView.reloadData()
    }
    
    // Prepares the add action view controller with delegate
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let addVC = segue.destination as? AddActionTableViewController {
            addVC.delegate = self
        }
    }
    
    // MARK: - TableView Data Source
    
    // Returns the number of category sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    // Returns the number of actions in each category section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    // Configures and returns the custom header view for each category section
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderView.identifier) as? SectionHeaderView else { return nil }
        let categoryName = sections[section].category
        header.configure(title: categoryName, section: section)
        header.delegate = self
        return header
    }
    
    // Returns fixed height for section headers
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    // Returns fixed height for action rows
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    // Configures and returns a cell for each action item
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuickActionCell", for: indexPath) as? QuickActionCell else { return UITableViewCell() }
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        cell.onInfoTapped = { [weak self] in self?.showActionDetails(for: item) }
        return cell
    }
    
    // MARK: - Swipe Actions
    
    // Provides swipe actions for deleting and renaming actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = self.sections[indexPath.section].items[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            self.sections[indexPath.section].items.remove(at: indexPath.row)
            if self.sections[indexPath.section].items.isEmpty {
                self.sections.remove(at: indexPath.section)
                tableView.deleteSections([indexPath.section], with: .fade)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (_, _, completion) in
            self?.showRenameAlert(for: item, section: indexPath.section, row: indexPath.row)
            completion(true)
        }
        renameAction.backgroundColor = .systemOrange
        renameAction.image = UIImage(systemName: "pencil")
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    // MARK: - Header Delegate
    
    // Handles taps on section headers and performs category-specific segues
    func didTapHeader(sectionIndex: Int, categoryName: String) {
        var segueID = ""
        
        switch categoryName {
        case "Office":
            segueID = "office"
        case "Family":
            segueID = "family"
        case "Friends":
            segueID = "friends"
        default:
            print("No segue configured for category: \(categoryName)")
            return
        }
        
        performSegue(withIdentifier: segueID, sender: self)
    }
    
    // MARK: - Helper Methods
    
    // Displays action details in an alert dialog
    private func showActionDetails(for item: RoutineConversation) {
        let message = item.description ?? "Status: \(item.status)"
        let alert = UIAlertController(title: item.conversationTopic, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Shows alert dialog for renaming an action
    private func showRenameAlert(for item: RoutineConversation, section: Int, row: Int) {
        let alert = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = item.conversationTopic }
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            var updatedItem = item
            updatedItem.conversationTopic = newName
            self.sections[section].items[row] = updatedItem
            self.tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - AddActionDelegate Implementation

extension QuickActionsViewController: AddActionDelegate {
    
    // Handles newly created actions by reloading data from repository
    func didCreateNewAction(_ action: RoutineConversation) {
        loadData()
        print("Action Added: \(action.conversationTopic) at \(action.startTime)")
    }
}
