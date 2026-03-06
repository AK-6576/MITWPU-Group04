//
//  HomeViewController.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 22/11/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//
import UIKit
import UserNotifications
import Foundation

class HomeViewController: UIViewController {
    
    // MARK: - Outlets & Properties
    @IBOutlet weak var tableView: UITableView!

    var quickActions: [RoutineConversation] = []
    var recentHistory: [Conversation] = []
    
    private let profileButton = UIButton(type: .custom)
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupProfileButton()
        loadSavedProfileImage()
        
        // Explicitly disable large titles — Login screen sets this to true.
        // Without this reset: (a) the table gets an extra top inset creating a gap,
        // and (b) every child VC pushed from Home inherits the large title.
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        // Show greeting in the tableHeaderView labels (32pt bold, looks like a native large title)
        // This avoids any nav bar large-title bleed to child screens.
        let name = UserDefaults.standard.string(forKey: "user_first_name") ?? "Steve"
        if let headerView = tableView.tableHeaderView as? GreetingViewCell {
            headerView.helloLabel.isHidden = false
            headerView.nameLabel.isHidden = false
            headerView.configure(name: name)
        }
        // Keep nav bar title empty on Home (greeting is in the header view above)
        navigationItem.title = ""
        
        navigationItem.hidesBackButton = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleProfileImageUpdate(_:)), name: NSNotification.Name("ProfileImageUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleProfileNameUpdate(_:)), name: NSNotification.Name("ProfileNameUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataUpdate), name: NSNotification.Name("ActionsUpdated"), object: nil)
    }
    
    @objc func handleDataUpdate() {
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        loadSavedProfileImage()
        
        // Force reset large titles every time Home appears.
        // This is critical because Login/CreateAccount set it to true globally.
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        // Refresh greeting name in the header view
        let name = UserDefaults.standard.string(forKey: "user_first_name") ?? "Steve"
        if let headerView = tableView.tableHeaderView as? GreetingViewCell {
            headerView.configure(name: name)
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification Handlers
    
    @objc func handleProfileNameUpdate(_ notification: Notification) {
        if let userInfo = notification.userInfo, let newName = userInfo["name"] as? String {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let headerView = self.tableView.tableHeaderView as? GreetingViewCell {
                    headerView.configure(name: newName)
                }
                UserDefaults.standard.set(newName, forKey: "user_first_name")
            }
        }
    }
    
    @objc func handleProfileImageUpdate(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            if let newImage = notification.object as? UIImage {
                self?.profileButton.setImage(newImage, for: .normal)
            }
        }
    }
    
    // MARK: - Data Loading & Logic
    
    func loadData() {
        
        let allItems = QuickActionsRepository.shared.getAllActions()
        
        let cutoffTime = Date().addingTimeInterval(-1800)
        let sortedFutureActions = allItems.filter { item in
            guard item.status != "Done", let itemDate = getDate(from: item.startTime) else { return false }
            return itemDate > cutoffTime
        }.sorted { (item1, item2) -> Bool in
            guard let date1 = getDate(from: item1.startTime),
                  let date2 = getDate(from: item2.startTime) else { return false }
            return date1 < date2
        }
        
        self.quickActions = sortedFutureActions
        
        self.recentHistory = Array(DataManager.shared.fetchConversations().prefix(2))
        
        syncNotifications(for: allItems)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func syncNotifications(for items: [RoutineConversation]) {
        let now = Date()
        for item in items {
            guard var targetDate = getDate(from: item.startTime) else { continue }
            if targetDate < now {
                if now.timeIntervalSince(targetDate) < 60 {
                    targetDate = now.addingTimeInterval(1)
                } else {
                    targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
                }
            }
            NotificationManager.shared.scheduleNotification(identifier: item.id, title: item.conversationTopic, body: "Join \(item.categoryTitle).", for: targetDate)
            
            let preNotificationDate = targetDate.addingTimeInterval(-300)
            if preNotificationDate > Date() {
                NotificationManager.shared.scheduleNotification(identifier: "\(item.id)_pre", title: item.conversationTopic, body: "Starts in 5 minutes.", for: preNotificationDate)
            }
        }
    }
    
    private func cancelNotifications(for item: RoutineConversation) {
        NotificationManager.shared.cancelNotification(identifier: item.id)
        NotificationManager.shared.cancelNotification(identifier: "\(item.id)_pre")
    }
    
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
        return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: now)
    }
    
    // MARK: - Edit Logic
    
    private func showEditSheet(for item: RoutineConversation, row: Int) {
        let alert = UIAlertController(title: "Edit Action", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = item.conversationTopic
            textField.placeholder = "Topic Name"
        }
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        if let currentTimeDate = getDate(from: item.startTime) { datePicker.date = currentTimeDate }
        alert.view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 60),
            datePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            datePicker.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let newTimeStr = formatter.string(from: datePicker.date)
            
            self.cancelNotifications(for: item)
            var updatedItem = item
            updatedItem.conversationTopic = newName
            updatedItem.startTime = newTimeStr
            QuickActionsRepository.shared.updateAction(updatedItem)
            self.syncNotifications(for: [updatedItem])
            
            if self.quickActions.indices.contains(row) {
                self.quickActions[row] = updatedItem
                self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
            }
            self.loadData()
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Actions & Navigation
    
    @IBAction func didTapNewConversation(_ sender: UITapGestureRecognizer) { performSegue(withIdentifier: "showNewConversation", sender: self) }
    @IBAction func didTapJoinConversation(_ sender: UITapGestureRecognizer) { performSegue(withIdentifier: "showJoinConversation", sender: self) }
    @IBAction func didTapQuickCaption(_ sender: UITapGestureRecognizer) { performSegue(withIdentifier: "Test1", sender: self) }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            if let destVC = segue.destination as? ProfileTableViewController {
                destVC.incomingName = UserDefaults.standard.string(forKey: "user_first_name") ?? "Steve"
            }
        } else if segue.identifier == "viewConvoCell" {
            guard let destVC = segue.destination as? ChatHistoryViewController,
                  let selectedConvo = sender as? Conversation else { return }
            destVC.histconversationData = selectedConvo
        }
    }
    
    // MARK: - UI Setup
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func setupProfileButton() {
        let size: CGFloat = 36
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        profileButton.frame = containerView.bounds
        profileButton.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
        profileButton.tintColor = .label
        profileButton.imageView?.contentMode = .scaleAspectFill
        profileButton.layer.cornerRadius = size / 2
        profileButton.clipsToBounds = true
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        containerView.addSubview(profileButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: containerView)
    }
    
    @objc private func profileTapped() { performSegue(withIdentifier: "showProfile", sender: self) }

    private func loadSavedProfileImage() {
        if let data = UserDefaults.standard.data(forKey: "profileImage"), let image = UIImage(data: data) {
            profileButton.setImage(image, for: .normal)
        }
    }
    
    private func presentInfoScreen(for item: RoutineConversation) {
        let alert = UIAlertController(title: item.conversationTopic, message: item.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView Delegate & DataSource
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return quickActions.isEmpty ? 1 : quickActions.count
        } else {
            return recentHistory.isEmpty ? 1 : recentHistory.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cellID = (section == 0) ? "QAHeaderCell" : "VCHeaderCell"
        guard let header = tableView.dequeueReusableCell(withIdentifier: cellID) as? HeaderCells else { return nil }
        header.titleLabel.text = (section == 0) ? "Quick Actions" : "View Conversations"
        header.subtitleLabel?.text = (section == 0) ? "Upcoming" : ""
        return header.contentView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0) ? 70 : 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if quickActions.isEmpty {
                return tableView.dequeueReusableCell(withIdentifier: "EmptyStateCell", for: indexPath)
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as? QuickActionTableViewCell else { return UITableViewCell() }
                let item = quickActions[indexPath.row]
                // Corrected isLastRow logic to handle more than 3 items correctly
                let isLastRow = indexPath.row == quickActions.count - 1
                cell.configure(with: item, isLast: isLastRow)
                cell.onInfoTapped = { [weak self] in self?.presentInfoScreen(for: item) }
                return cell
            }
        } else {
            if recentHistory.isEmpty {
                let emptyCell = UITableViewCell(style: .default, reuseIdentifier: nil)
                emptyCell.textLabel?.text = "No recent conversations."
                emptyCell.textLabel?.textColor = .systemGray
                emptyCell.textLabel?.textAlignment = .center
                emptyCell.backgroundColor = .clear
                emptyCell.selectionStyle = .none
                return emptyCell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCardCell", for: indexPath) as? ConversationCardCell else { return UITableViewCell() }
                let historyItem = recentHistory[indexPath.row]
                cell.configure(with: historyItem)
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if quickActions.isEmpty { return }
            let item = quickActions[indexPath.row]
            var segueID = ""
            switch item.categoryTitle {
            case "Office": segueID = "office"
            case "Family": segueID = "family"
            case "Friends": segueID = "friends"
            default: return
            }
            performSegue(withIdentifier: segueID, sender: item)
        } else {
            if recentHistory.isEmpty { return }
            let historyItem = recentHistory[indexPath.row]
            performSegue(withIdentifier: "viewConvoCell", sender: historyItem)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 0 && !quickActions.isEmpty else { return nil }
        
        let item = quickActions[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            self.cancelNotifications(for: item)
            QuickActionsRepository.shared.deleteAction(item)
            self.quickActions.remove(at: indexPath.row)
            
            if self.quickActions.isEmpty {
                self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
            } else {
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (_, _, completion) in
            self?.showEditSheet(for: item, row: indexPath.row)
            completion(true)
        }
        editAction.backgroundColor = .systemOrange
        editAction.image = UIImage(systemName: "pencil")
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    // MARK: - Context Menu (Same as ViewConversationCollection)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.section == 1 && !recentHistory.isEmpty else { return nil }
        
        let historyItem = recentHistory[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            
            // 1. PIN ACTION
            let isPinned = historyItem.isPinned
            let pinTitle = isPinned ? "Unpin" : "Pin"
            let pinImage = isPinned ? UIImage(systemName: "pin.slash") : UIImage(systemName: "pin")
            let pinAction = UIAction(title: pinTitle, image: pinImage) { _ in
                historyItem.isPinned.toggle()
                DataManager.shared.saveData()
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            // 2. RENAME ACTION
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in
                self.showRenameAlert(for: indexPath)
            }
            
            // 3. DELETE ACTION
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.showDeleteConfirmation(for: indexPath)
            }
            
            return UIMenu(title: "", children: [pinAction, renameAction, deleteAction])
        }
    }
    
    // MARK: - Helper Methods for Context Menu
    func showRenameAlert(for indexPath: IndexPath) {
        let historyItem = recentHistory[indexPath.row]
        let alert = UIAlertController(title: "Rename Conversation", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = historyItem.title
            textField.autocapitalizationType = .sentences
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                historyItem.title = newName
                DataManager.shared.saveData()
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func showDeleteConfirmation(for indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Conversation?", message: "This action cannot be undone.", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            let historyItem = self.recentHistory[indexPath.row]
            DataManager.shared.deleteConversation(historyItem)
            self.recentHistory.remove(at: indexPath.row)
            
            if self.recentHistory.isEmpty {
                self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            } else {
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
