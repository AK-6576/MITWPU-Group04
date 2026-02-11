//
//  QuickActionsViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 05/1/26.

import UIKit

class QuickActionsViewController: UITableViewController {
    
    var sections: [RoutineSection] = []

    // Function - Initializes the view lifecycle, setting the title and removing default header padding.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Quick Actions"

        
        tableView.tableHeaderView = UIView()
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    // Function - Called when the view is about to appear, triggering the data load process.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    // Function - Fetches grouped sections from the repository, filters out completed items, and reloads the table view.
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
    
    // MARK: - Navigation & Segues
    
    // Function - Prepares for navigation, setting delegates for the add screen or logging chat transitions.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let addVC = segue.destination as? AddActionTableViewController {
            addVC.delegate = self
        }
        
        let chatSegueIDs = ["officeChat", "familyChat", "friendsChat"]
        
        if let segueID = segue.identifier, chatSegueIDs.contains(segueID) {
            
            if let selectedItem = sender as? RoutineConversation {
                print("Opening Chat for: \(selectedItem.conversationTopic) via segue: \(segueID)")
            }
        }
    }
    
    // MARK: - TableView Delegate (Selection)
    
    // Function - Handles row selection, determining the specific chat segue identifier based on the category and performing the navigation.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionData = sections[indexPath.section]
        let item = sectionData.items[indexPath.row]
        let category = sectionData.category
        
        var segueID = ""
        
        switch category {
        case "Family":
            segueID = "familyChat"
        case "Friends":
           
            segueID = "friendChat"
        case "Office": // Note: Fix the "Famiy" typo here too
            segueID = "officeChat"
        default:
            print("No chat segue configured for category: \(category)")
            return
        }
        
        performSegue(withIdentifier:segueID , sender: item)
    }
    
    // MARK: - Header Navigation
    
    // Function - Handles taps on section headers to navigate to the full category view using specific segue identifiers.
    func didTapHeader(sectionIndex: Int, categoryName: String) {
        
        var segueID = ""
        
        switch categoryName {
        case "Office":
            segueID = "familyDetail"
        case "Family":
            segueID = "familyDetail"
        case "Friends":
            segueID = "familyDetail"
            
        default:
            print("No segue configured for category: \(categoryName)")
            return
        }
        if shouldPerformSegue(withIdentifier: segueID, sender: self) {
            performSegue(withIdentifier: segueID, sender: self)
        } else {
            print("Error: Segue identifier '\(segueID)' not found in Storyboard.")
        }
    }
    
    // MARK: - TableView Data Source
    
    // Function - Returns the total number of sections in the table view.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    // Function - Returns the number of rows (items) in a specific section.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    // Function - Dequeues and configures a custom header view with the category title and a tap handler.
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let header = tableView.dequeueReusableCell(withIdentifier: "CategoryTableViewCell") as? CategoryTableViewCell else {
            return nil
        }
        
        let categoryName = sections[section].category
        
        header.titleLabel.text = categoryName
        
        header.onChevronTapped = { [weak self] in
            self?.didTapHeader(sectionIndex: section, categoryName: categoryName)
        }
        
        return header
    }
    
    // Function - Returns the automatic height for section headers.
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // Function - Returns an estimated height for section headers to improve scrolling performance.
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    // Function - Returns the fixed height for table view rows.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    // Function - Dequeues and configures a cell with the specific action data and info button handler.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuickActionCell", for: indexPath) as? QuickActionCell else { return UITableViewCell() }
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        cell.onInfoTapped = { [weak self] in self?.showActionDetails(for: item) }
        return cell
    }
    
    // MARK: - Swipe Actions
    
    // Function - Configures swipe actions for deleting and renaming items within the table.
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = self.sections[indexPath.section].items[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            QuickActionsRepository.shared.deleteAction(item)
            

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
        
        let renameAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (_, _, completion) in
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
    
    // Function - Displays an alert with details about the selected action.
    private func showActionDetails(for item: RoutineConversation) {
        let message = item.description ?? "Status: \(item.status)"
        let alert = UIAlertController(title: item.conversationTopic, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Function - Presents an alert with a text field to rename the selected action and updates the repository.
    private func showRenameAlert(for item: RoutineConversation, section: Int, row: Int) {
        let alert = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = item.conversationTopic }
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            var updatedItem = item
            updatedItem.conversationTopic = newName
            QuickActionsRepository.shared.updateAction(updatedItem)
            
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
    
    // Function - Delegate method called when a new action is created; adds it to the repository and reloads the data.
    func didCreateNewAction(_ action: RoutineConversation) {
        QuickActionsRepository.shared.addAction(action)
        loadData()
        print("Action Added and Saved: \(action.conversationTopic)")
    }
}
