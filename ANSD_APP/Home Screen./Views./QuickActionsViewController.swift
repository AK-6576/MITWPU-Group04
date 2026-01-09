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
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.identifier)
        tableView.tableHeaderView = UIView()
        
        loadData()
    }
    
    func loadData() {
        self.sections = QuickActionsRepository.getGroupedSections()
        tableView.reloadData()
    }
    
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderView.identifier) as? SectionHeaderView else { return nil }
        
        let categoryName = sections[section].category
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
        
        cell.onInfoTapped = { [weak self] in
            self?.showActionDetails(for: item)
        }
        
        return cell
    }
    
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
        deleteAction.backgroundColor = UIColor.systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (_, _, completion) in
            self?.showRenameAlert(for: item, section: indexPath.section, row: indexPath.row)
            completion(true)
        }
        renameAction.backgroundColor = UIColor.systemOrange
        renameAction.image = UIImage(systemName: "pencil")
        
        // Removed Info Action from swipe since button exists on cell
        let config = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    // MARK: - Header Delegate
    func didTapHeader(sectionIndex: Int, categoryName: String) {
        
        var storyboardName = ""
        
        switch categoryName {
        case "Friends":
            storyboardName = "Friends"
        case "Family":
            storyboardName = "RoutineConvo 2"
        case "Office":
            storyboardName = "RoutineConvo"
        default:
            print("No storyboard configured for: \(categoryName)")
            return
        }
        
        if !storyboardName.isEmpty {
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            
            if var targetVC = storyboard.instantiateInitialViewController() {
                
                // If the storyboard starts with a NavigationController, grab the topVC
                if let navVC = targetVC as? UINavigationController, let topVC = navVC.topViewController {
                    targetVC = topVC
                }
                
                navigationController?.pushViewController(targetVC, animated: true)
            }
        }
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
        var allItems = sections.flatMap { $0.items }
        allItems.append(action)
        
        let groupedDictionary = Dictionary(grouping: allItems) { $0.categoryTitle }
        self.sections = groupedDictionary.map { (key, value) in
            RoutineSection(category: key, items: value)
        }.sorted { $0.category < $1.category }
        
        tableView.reloadData()
    }
}
