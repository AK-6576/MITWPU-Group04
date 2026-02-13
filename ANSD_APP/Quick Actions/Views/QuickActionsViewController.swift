import UIKit

class QuickActionsViewController: UITableViewController {
    
    var sections: [RoutineSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Quick Actions"
        tableView.tableHeaderView = UIView()
        tableView.sectionHeaderTopPadding = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    private func loadData() {
        let allSections = QuickActionsRepository.shared.getGroupedSections()
        self.sections = allSections.compactMap { section in
            let activeItems = section.items.filter { $0.status != "Done" }
            if activeItems.isEmpty { return nil }
            
            var filteredSection = section
            filteredSection.items = activeItems
            return filteredSection
        }
        tableView.reloadData()
    }
    
    // MARK: - Navigation & Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 1. Handle Add Screen Delegate
        if let addVC = segue.destination as? AddActionTableViewController {
            addVC.delegate = self
        }
        
        // 2. Handle Chat Screen Navigation (Injecting the dynamic title)
        let chatSegueIDs = ["officeChat", "familyChat", "friendChat", "genericChat"]
        
        // Update your prepare(for:segue:) method
        if let segueID = segue.identifier, chatSegueIDs.contains(segueID) {
            if let selectedItem = sender as? RoutineConversation {
                if let chatVC = segue.destination as? FamilyJoinViewController {
                    
                    // 1. Set the Dynamic Title
                    chatVC.sessionTitle = "\(selectedItem.categoryTitle) Session"
                    
                    // 2. Pass the Category String directly (Fixes the compiler error)
                    chatVC.category = selectedItem.categoryTitle
                }
                print("Opening Chat for Category: \(selectedItem.categoryTitle)")
            }
        }
        
        // 3. Handle Category Detail (Header Taps)
        if segue.identifier == "categoryDetail", let categoryName = sender as? String {
            // You can set the title for the detail view here as well
            segue.destination.title = categoryName
        }
    }
    
    // MARK: - TableView Delegate (Selection)
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionData = sections[indexPath.section]
        let item = sectionData.items[indexPath.row]
        let category = sectionData.category
        
        var segueID = ""
        
        // Mapping Logic: Predefined categories go to specific segues,
        // while all others (new/custom) go to a generic chat segue.
        switch category {
        case "Family":
            segueID = "familyChat"
        case "Friends":
            segueID = "friendChat"
        case "Office":
            segueID = "officeChat"
        default:
            // This handles "Orasad" or any other custom category
            segueID = "genericChat"
        }
        
        performSegue(withIdentifier: segueID, sender: item)
    }
    
    // MARK: - Header Navigation
    
    func didTapHeader(sectionIndex: Int, categoryName: String) {
        // All categories (Predefined + Custom) now use the same detail screen segue
        let segueID = "categoryDetail"
        
        if shouldPerformSegue(withIdentifier: segueID, sender: self) {
            performSegue(withIdentifier: segueID, sender: categoryName)
        } else {
            print("Error: Segue identifier '\(segueID)' not found. Check Storyboard.")
        }
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
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
    
    // MARK: - Cell & Swipe Configuration
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuickActionCell", for: indexPath) as? QuickActionCell else { return UITableViewCell() }
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        cell.onInfoTapped = { [weak self] in self?.showActionDetails(for: item) }
        return cell
    }
    
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
            QuickActionsRepository.shared.updateAction(updatedItem)
            
            self.sections[section].items[row] = updatedItem
            self.tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - AddActionDelegate

extension QuickActionsViewController: AddActionDelegate {
    func didCreateNewAction(_ action: RoutineConversation) {
        QuickActionsRepository.shared.addAction(action)
        loadData()
    }
}
