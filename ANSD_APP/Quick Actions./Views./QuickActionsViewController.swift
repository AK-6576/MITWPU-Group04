//
//  QuickActionsViewController.swift
//  ANSD_APP
//

import UIKit

class QuickActionsViewController: UITableViewController, SectionHeaderDelegate {
    
    var sections: [RoutineSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Quick Actions"
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.identifier)
        tableView.tableHeaderView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    private func loadData() {
        let allSections = QuickActionsRepository.shared.getGroupedSections()
        
        // Filter out items marked as "Done"
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
    
    // MARK: - Navigation & Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // 1. Handle "Add Action" Segue
        if let addVC = segue.destination as? AddActionTableViewController {
            addVC.delegate = self
        }
        
        // 2. Handle Chat Screen Segues (Cell Taps)
        // We check if the identifier is one of our specific chat segues
        let chatSegueIDs = ["officeChat", "familyChat", "friendsChat"]
        
        if let segueID = segue.identifier, chatSegueIDs.contains(segueID) {
            
            // Retrieve the data item passed from didSelectRowAt
            if let selectedItem = sender as? RoutineConversation {
                print("Opening Chat for: \(selectedItem.conversationTopic) via segue: \(segueID)")
                
                // TODO: Pass data to your specific Chat View Controller here.
                // Example:
                // if let chatVC = segue.destination as? ChatViewController {
                //     chatVC.conversationData = selectedItem
                // }
            }
        }
    }
    
    // MARK: - TableView Delegate (Cell Selection)
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 1. Get the item and category
        let sectionData = sections[indexPath.section]
        let item = sectionData.items[indexPath.row]
        let category = sectionData.category
        
        // 2. Determine Segue ID for CHAT (Unique from Header Segues)
        var segueID = ""
        
        switch category {
        case "Office":
            segueID = "officeChat"
            
        case "Family":
            segueID = "familyChat"
            
        case "Friends":
            segueID = "friendsChat"
            
        default:
            print("No chat segue configured for category: \(category)")
            return
        }
        
        // 3. Perform Segue passing the item data
        performSegue(withIdentifier: segueID, sender: item)
    }
    
    // MARK: - Header Delegate (Section Header Taps)
    
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
            print("No list segue configured for category: \(categoryName)")
            return
        }
        
        performSegue(withIdentifier: segueID, sender: self)
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderView.identifier) as? SectionHeaderView else { return nil }
        let categoryName = sections[section].category
        header.configure(title: categoryName, section: section)
        header.delegate = self
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 50 }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 75 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuickActionCell", for: indexPath) as? QuickActionCell else { return UITableViewCell() }
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        cell.onInfoTapped = { [weak self] in self?.showActionDetails(for: item) }
        return cell
    }
    
    // MARK: - Swipe Actions
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = self.sections[indexPath.section].items[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            // Remove from local array
            self.sections[indexPath.section].items.remove(at: indexPath.row)
            
            // Handle empty section removal
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
    
    // MARK: - Helper Methods
    
    private func showActionDetails(for item: RoutineConversation) {
        let message = item.description ?? "Status: \(item.status)"
        let alert = UIAlertController(title: item.conversationTopic, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
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
    func didCreateNewAction(_ action: RoutineConversation) {
        loadData()
        print("Action Added: \(action.conversationTopic) at \(action.startTime)")
    }
}
