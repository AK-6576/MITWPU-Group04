//
//  QuickActionsViewController.swift
//  ANSD_APP
//

import UIKit

class QuickActionsViewController: UITableViewController, SectionHeaderDelegate {
    
    // Data Source
    var sections: [RoutineSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Quick Actions"
        
        // 1. Register Header
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.identifier)
        
        // 2. Remove empty cell separators
        tableView.tableHeaderView = UIView()
        
        // 3. Load Data
        loadData()
    }
    
    func loadData() {
        self.sections = QuickActionsRepository.getGroupedSections()
        tableView.reloadData()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let addVC = segue.destination as? AddActionTableViewController {
            addVC.delegate = self
        }
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    // MARK: - Header Config
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderView.identifier) as? SectionHeaderView else { return nil }
        
        let categoryName = sections[section].category
        // Clean configure (no colors)
        header.configure(title: categoryName, section: section)
        header.delegate = self
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuickActionCell", for: indexPath) as? QuickActionCell else {
            return UITableViewCell()
        }
        
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        
        // Optional: Tint the icon image using Utils
        // cell.iconImageView?.tintColor = getColorForCategory(item.categoryTitle)
        
        cell.onInfoTapped = { [weak self] in
            self?.showActionDetails(for: item)
        }
        
        return cell
    }
    
    // MARK: - Swipe Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let item = self.sections[indexPath.section].items[indexPath.row]
        
        // 1. DELETE
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            // Remove from array
            self.sections[indexPath.section].items.remove(at: indexPath.row)
            
            // Update Table View
            if self.sections[indexPath.section].items.isEmpty {
                self.sections.remove(at: indexPath.section)
                tableView.deleteSections([indexPath.section], with: .fade)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            completion(true)
        }
        deleteAction.backgroundColor = UIColor.systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        // 2. RENAME
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (_, _, completion) in
            self?.showRenameAlert(for: item, section: indexPath.section, row: indexPath.row)
            completion(true)
        }
        renameAction.backgroundColor = UIColor.systemOrange
        renameAction.image = UIImage(systemName: "pencil")
        
        // 3. INFO
        let infoAction = UIContextualAction(style: .normal, title: "Info") { [weak self] (_, _, completion) in
            self?.showActionDetails(for: item)
            completion(true)
        }
        infoAction.backgroundColor = UIColor.systemBlue
        infoAction.image = UIImage(systemName: "info.circle")
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction, renameAction, infoAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    // MARK: - Header Delegate
    func didTapHeader(sectionIndex: Int, categoryName: String) {
        print("Header tapped: \(categoryName)")
        // Implement expansion/navigation logic here
    }
    
    // MARK: - Helpers
    func showActionDetails(for item: RoutineConversation) {
        let message = item.description ?? "Status: \(item.status)"
        let alert = UIAlertController(title: item.conversationTopic, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showRenameAlert(for item: RoutineConversation, section: Int, row: Int) {
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

// MARK: - AddActionDelegate
extension QuickActionsViewController: AddActionDelegate {
    func didCreateNewAction(_ action: RoutineConversation) {
        // 1. Flatten existing items
        var allItems = sections.flatMap { $0.items }
        // 2. Add new item
        allItems.append(action)
        
        // 3. Regroup and Sort
        let groupedDictionary = Dictionary(grouping: allItems) { $0.categoryTitle }
        self.sections = groupedDictionary.map { (key, value) in
            RoutineSection(category: key, items: value)
        }.sorted { $0.category < $1.category }
        
        // 4. Reload
        tableView.reloadData()
    }
}
