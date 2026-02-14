import UIKit

class QuickActionsViewController: UITableViewController {
    
    var sections: [RoutineSection] = []

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Quick Actions"
        
        // Clean up empty rows and headers
        tableView.tableHeaderView = UIView()
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        let allSections = QuickActionsRepository.shared.getGroupedSections()
        
        // Filter out "Done" items and hide empty sections
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
        // 1. Handle Add Screen Delegate
        if let addVC = segue.destination as? AddActionTableViewController {
            addVC.delegate = self
        }
        
        // 2. Handle Chat Screen Navigation (Injecting the dynamic title)
        let chatSegueIDs = ["officeChat", "familyChat", "friendChat", "genericChat"]
        
        if let segueID = segue.identifier, chatSegueIDs.contains(segueID) {
            if let selectedItem = sender as? RoutineConversation {
                if let chatVC = segue.destination as? FamilyJoinViewController {
                    
                    // 1. Set the Dynamic Title
                    chatVC.sessionTitle = "\(selectedItem.categoryTitle) Session"
                    
                    // 2. Pass the Category String
                    chatVC.category = selectedItem.categoryTitle
                }
                print("Opening Chat for Category: \(selectedItem.categoryTitle)")
            }
        }
        
        // 3. Handle Category Detail (Header Taps)
        if segue.identifier == "categoryDetail", let categoryName = sender as? String {
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
        
        // Mapping Logic: Predefined categories go to specific segues
        switch category {
        case "Family":
            segueID = "familyChat"
        case "Friends":
            segueID = "friendChat"
        case "Office":
            segueID = "officeChat"
        default:
            // This handles custom categories
            segueID = "genericChat"
        }
        
        performSegue(withIdentifier: segueID, sender: item)
    }
    
    // MARK: - Header Navigation logic
    
    func didTapHeader(sectionIndex: Int, categoryName: String) {
        let segueID = "categoryDetail"
        
        if shouldPerformSegue(withIdentifier: segueID, sender: self) {
            performSegue(withIdentifier: segueID, sender: categoryName)
        } else {
            print("Error: Segue identifier '\(segueID)' not found in Storyboard.")
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
    
    // MARK: - Swipe Actions (Delete & Edit)
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = self.sections[indexPath.section].items[indexPath.row]
        
        // Delete Action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { completion(false); return }
            
            QuickActionsRepository.shared.deleteAction(item)
            
            // Remove from local array
            self.sections[indexPath.section].items.remove(at: indexPath.row)
            
            // Update UI (Row vs Section deletion)
            if self.sections[indexPath.section].items.isEmpty {
                self.sections.remove(at: indexPath.section)
                tableView.deleteSections([indexPath.section], with: .fade)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        // Edit Action (Triggers the Complex Edit Sheet)
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (_, _, completion) in
            self?.showEditSheet(for: item, section: indexPath.section, row: indexPath.row)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        editAction.image = UIImage(systemName: "pencil")
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
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
    
    // Presents a native alert with a Text Field and embedded Date Picker
    private func showEditSheet(for item: RoutineConversation, section: Int, row: Int) {
        let alert = UIAlertController(title: "Edit Action", message: "Update the topic or time below.", preferredStyle: .alert)
        
        // 1. Add Text Field
        alert.addTextField { textField in
            textField.text = item.conversationTopic
            textField.placeholder = "Topic Name"
            textField.autocapitalizationType = .sentences
            textField.clearButtonMode = .whileEditing
        }
        
        // 2. Create Date Picker
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Set existing time
        if let currentTimeDate = getDate(from: item.startTime) {
            datePicker.date = currentTimeDate
        }

        // 3. Embed DatePicker in a container View Controller (Native styling fix)
        let containerVC = UIViewController()
        containerVC.preferredContentSize = CGSize(width: 270, height: 120)
        containerVC.view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
            datePicker.topAnchor.constraint(equalTo: containerVC.view.topAnchor),
            datePicker.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor)
        ])
        
        alert.setValue(containerVC, forKey: "contentViewController")
        
        // 4. Save Action
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            // Format new time string
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let newTimeStr = formatter.string(from: datePicker.date)
            
            // Update Item
            var updatedItem = item
            updatedItem.conversationTopic = newName
            updatedItem.startTime = newTimeStr
            
            // Persist changes
            QuickActionsRepository.shared.updateAction(updatedItem)
            
            // Update TableView
            if self.sections.indices.contains(section), self.sections[section].items.indices.contains(row) {
                self.sections[section].items[row] = updatedItem
                self.tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    // Helper to convert string time to Date object
    private func getDate(from timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let timeDate = formatter.date(from: timeString) else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                             minute: timeComponents.minute ?? 0,
                             second: 0,
                             of: now)
    }
}

// MARK: - AddActionDelegate Implementation

extension QuickActionsViewController: AddActionDelegate {
    
    func didCreateNewAction(_ action: RoutineConversation) {
        QuickActionsRepository.shared.addAction(action)
        loadData()
        print("Action Added and Saved: \(action.conversationTopic)")
    }
}
