//
//  HomeViewController.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 12/12/25.
//

import UIKit
import UserNotifications
import Foundation

class HomeViewController: UIViewController {
    
    // MARK: - Outlets & Properties
    @IBOutlet weak var tableView: UITableView!

    var quickActions: [RoutineConversation] = []
    var routineConversations: [RoutineConversation] = []
    
    private let profileButton = UIButton(type: .custom)
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupProfileButton()
        loadSavedProfileImage()
        
        // Hide the default back button to prevent navigation issues
        navigationItem.hidesBackButton = true
        
        // Request Notification Permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        
        // === INSTANT UPDATE LISTENERS ===
        // 1. Listen for Image changes
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleProfileImageUpdate(_:)),
                                               name: NSNotification.Name("ProfileImageUpdated"),
                                               object: nil)
        
        // 2. Listen for Name changes (This fixes the "Steve" vs "Mike" issue instantly)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleProfileNameUpdate(_:)),
                                               name: NSNotification.Name("ProfileNameUpdated"),
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        loadSavedProfileImage()
        
        // Force a check when the view appears, just in case
        updateGreetingHeader()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Header Update Logic
    
    func updateGreetingHeader(forceName: String? = nil) {
        // Use the forced name if provided (from Notification), otherwise read from disk
        let nameToShow = forceName ?? UserDefaults.standard.string(forKey: "user_first_name") ?? "Steve"
        
        // Ensure this happens on the Main Thread (UI updates must remain here)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Access the header view
            if let headerView = self.tableView.tableHeaderView as? GreetingViewCell {
                headerView.configure(name: nameToShow)
                
                // Force layout update if needed
                headerView.setNeedsLayout()
                headerView.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc func handleProfileNameUpdate(_ notification: Notification) {
        // This runs instantly when you type in the Profile screen
        if let userInfo = notification.userInfo,
           let newName = userInfo["name"] as? String {
            updateGreetingHeader(forceName: newName)
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
        // Filter out "Done" items
        let allItems = QuickActionsRepository.shared.getAllActions().filter { $0.status != "Done" }
        
        let cutoffTime = Date().addingTimeInterval(-1800) // 30 mins ago
        
        // Sort future actions
        let sortedFutureActions = allItems.filter { item in
            guard let itemDate = getDate(from: item.startTime) else { return false }
            return itemDate > cutoffTime
        }.sorted { (item1, item2) -> Bool in
            guard let date1 = getDate(from: item1.startTime),
                  let date2 = getDate(from: item2.startTime) else { return false }
            return date1 < date2
        }

        self.quickActions = sortedFutureActions
        self.routineConversations = allItems
        
        syncNotifications(for: allItems)
        
        self.tableView.reloadData()
    }
    
    private func syncNotifications(for items: [RoutineConversation]) {
        let now = Date()
        
        for item in items {
            guard var targetDate = getDate(from: item.startTime) else { continue }
            
            // Adjust date if it passed already
            if targetDate < now {
                if now.timeIntervalSince(targetDate) < 60 {
                    targetDate = now.addingTimeInterval(1)
                } else {
                    targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
                }
            }
            
            // Schedule Main Notification
            NotificationManager.shared.scheduleNotification(
                identifier: item.id,
                title: item.conversationTopic,
                body: "Join \(item.categoryTitle).",
                for: targetDate
            )
            
            // Schedule Pre-Notification (5 mins before)
            let preNotificationDate = targetDate.addingTimeInterval(-300)
            if preNotificationDate > Date() {
                NotificationManager.shared.scheduleNotification(
                    identifier: "\(item.id)_pre",
                    title: item.conversationTopic,
                    body: "Starts in 5 minutes.",
                    for: preNotificationDate
                )
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
        
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                             minute: timeComponents.minute ?? 0,
                             second: 0,
                             of: now)
    }
    
    // MARK: - Edit Logic
    
    private func showEditSheet(for item: RoutineConversation, row: Int) {
        let alert = UIAlertController(title: "Edit Action", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = item.conversationTopic
            textField.placeholder = "Topic Name"
            textField.clearButtonMode = .whileEditing
        }
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        if let currentTimeDate = getDate(from: item.startTime) {
            datePicker.date = currentTimeDate
        }

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
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            formatter.locale = Locale(identifier: "en_US_POSIX")
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
    
    @IBAction func didTapNewConversation(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showNewConversation", sender: self)
    }

    @IBAction func didTapJoinConversation(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showJoinConversation", sender: self)
    }

    @IBAction func didTapQuickCaption(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "Test1", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            if let destVC = segue.destination as? ProfileTableViewController {
                // Pass current name so Profile screen doesn't reset to "Steve" initially
                let currentName = UserDefaults.standard.string(forKey: "user_first_name") ?? "Steve"
                destVC.incomingName = currentName
            }
        }
        else if segue.identifier == "viewConvoCell" {
            guard let destVC = segue.destination as? ChatHistoryViewController,
                  let selectedItem = sender as? RoutineConversation else { return }
            
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
    
    @objc private func profileTapped() {
        performSegue(withIdentifier: "showProfile", sender: self)
    }

    private func loadSavedProfileImage() {
        if let data = UserDefaults.standard.data(forKey: "profileImage"),
           let image = UIImage(data: data) {
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
        return 2 // 0: Quick Actions, 1: Routine Conversations
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return min(quickActions.count, 3) }
        return min(routineConversations.count, 2)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cellID = (section == 0) ? "QAHeaderCell" : "VCHeaderCell"
        guard let header = tableView.dequeueReusableCell(withIdentifier: cellID) as? HeaderCells else { return nil }

        if section == 0 {
            header.titleLabel.text = "Quick Actions"
            header.subtitleLabel?.text = "Upcoming"
        } else {
            header.titleLabel.text = "View Conversations"
            header.subtitleLabel?.text = ""
        }
        return header.contentView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0) ? 70 : 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as? QuickActionTableViewCell else { return UITableViewCell() }
            let item = quickActions[indexPath.row]
            let isLastRow = indexPath.row == min(quickActions.count, 3) - 1
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
        // Safely perform segue
        performSegue(withIdentifier: segueID, sender: item)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 0 else { return nil }
        let item = quickActions[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            self.cancelNotifications(for: item)
            QuickActionsRepository.shared.deleteAction(item)
            self.quickActions.remove(at: indexPath.row)
            if self.quickActions.count >= 3 {
                self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
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
}
