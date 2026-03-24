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
import FirebaseAuth

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
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        let name = UserDefaults.standard.string(forKey: "user_first_name") ?? "User"
        if let headerView = tableView.tableHeaderView as? GreetingViewCell {
            headerView.configure(name: name)
            // Keep original header height so all action cards remain visible
            var frame = headerView.frame
            frame.size.height = 333
            headerView.frame = frame
            tableView.tableHeaderView = headerView
        }
        
        navigationItem.title = ""
        navigationItem.hidesBackButton = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        
        // RESTORED: Observers
        NotificationCenter.default.addObserver(self, selector: #selector(handleProfileImageUpdate(_:)), name: NSNotification.Name("ProfileImageUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleProfileNameUpdate(_:)), name: NSNotification.Name("ProfileNameUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataUpdate), name: NSNotification.Name("ActionsUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataUpdate), name: NSNotification.Name("ConversationHistoryUpdated"), object: nil)
    }
    
    @objc func handleDataUpdate() {
        print("HomeViewController: Received ConversationHistoryUpdated notification.")
        DispatchQueue.main.async { [weak self] in
            self?.loadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        loadSavedProfileImage()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        let name = UserDefaults.standard.string(forKey: "user_first_name") ?? "User"
        if let headerView = tableView.tableHeaderView as? GreetingViewCell {
            headerView.configure(name: name)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - RESTORED: Profile Handlers
    
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
    
    // MARK: - Queue Logic & Data Loading
    
    func loadData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("HomeViewController: loadData() called on Main Thread. Fetching...")
            
            // 1. Quick Actions Queue: Fetched via Repository (Top 3 Upcoming)
            self.quickActions = QuickActionsRepository.shared.getUpcomingActions(limit: 3)
            
            // 2. Recent History Queue: Limit visible to TOP 2
            let allConversations = DataManager.shared.fetchConversations()
            self.recentHistory = Array(allConversations.prefix(2))
            
            self.tableView.reloadData()
        }
    }
    
    // Queue Deletion Logic
    private func performQueueDeletion(for section: Int, at indexPath: IndexPath) {
        if section == 0 {
            let item = quickActions[indexPath.row]
            QuickActionsRepository.shared.deleteAction(item)
        } else {
            let historyItem = recentHistory[indexPath.row]
            DataManager.shared.deleteConversation(historyItem)
        }
        
        loadData()
        
        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(integer: section), with: .automatic)
        }
    }

    // MARK: - Navigation Handlers
    
    @IBAction func didTapNewConversation(_ sender: UITapGestureRecognizer) { performSegue(withIdentifier: "showNewConversation", sender: self) }
    @IBAction func didTapJoinConversation(_ sender: UITapGestureRecognizer) { performSegue(withIdentifier: "showJoinConversation", sender: self) }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            if let destVC = segue.destination as? ProfileTableViewController {
                destVC.incomingName = UserDefaults.standard.string(forKey: "user_first_name") ?? "User"
            }
        } else if segue.identifier == "viewConvoCell" {
            guard let destVC = segue.destination as? ChatHistoryViewController,
                  let selectedConvo = sender as? Conversation else { return }
            destVC.histconversationData = selectedConvo
        } else if segue.identifier == "showJoinConversation" {
            // Participant joining from a Quick Action cell
            if let selectedItem = sender as? RoutineConversation,
               let destVC = segue.destination as? SessionSelectionViewController {
                destVC.prefilledRoomCode = selectedItem.roomCode
            }
        } else {
            // Dashboard Quick Actions -> Chat (Direct Start for Host)
            let dashboardSegueIDs = ["office", "family", "friends"]
            if let segueID = segue.identifier, dashboardSegueIDs.contains(segueID) {
                if let selectedItem = sender as? RoutineConversation {
                    if let chatVC = segue.destination as? ActionJoinViewController {
                        chatVC.sessionTitle = "\(selectedItem.conversationTopic) Session" // Use topic as title
                        chatVC.category = selectedItem.categoryTitle
                        chatVC.roomCode = selectedItem.roomCode
                        chatVC.participantNames = selectedItem.participantNames
                    }
                }
            }
        }
    }

    // MARK: - UI Support Methods
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 80
    }
    
    private func setupProfileButton() {
        let size: CGFloat = 36
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        profileButton.frame = containerView.bounds
        profileButton.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
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
    
}

// MARK: - TableView Delegate & DataSource (RESTORED HEADERS)
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return quickActions.isEmpty ? 1 : quickActions.count
        } else {
            return recentHistory.isEmpty ? 1 : recentHistory.count
        }
    }

    // RESTORED: Heading Labels Logic
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cellID = (section == 0) ? "QAHeaderCell" : "VCHeaderCell"
        guard let header = tableView.dequeueReusableCell(withIdentifier: cellID) as? HeaderCells else { return nil }
        header.titleLabel.text = (section == 0) ? "Quick Actions" : "View Conversations"
        return header.contentView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 28 : 38
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 24 : .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if quickActions.isEmpty {
                return tableView.dequeueReusableCell(withIdentifier: "EmptyStateCell", for: indexPath)
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as? QuickActionTableViewCell else { return UITableViewCell() }
                let item = quickActions[indexPath.row]
                cell.configure(with: item, isLast: indexPath.row == quickActions.count - 1)
                return cell
            }
        } else {
            if recentHistory.isEmpty {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "No recent conversations."
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = .systemGray
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCardCell", for: indexPath) as? ConversationCardCell else { return UITableViewCell() }
                cell.configure(with: recentHistory[indexPath.row])
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && !quickActions.isEmpty {
            let item = quickActions[indexPath.row]
            
            // ROLE-BASED NAVIGATION
            let currentUID = Auth.auth().currentUser?.uid
            if let host = item.hostUID, host != currentUID {
                // I am a participant -> Go to Join screen with Room ID pre-filled
                performSegue(withIdentifier: "showJoinConversation", sender: item)
            } else {
                // I am the host (or hostUID missing) -> Go to direct start/join transcription
                var segueID = ""
                switch item.categoryTitle {
                    case "Office": segueID = "office"
                    case "Family": segueID = "family"
                    case "Friends": segueID = "friends"
                    default: return
                }
                performSegue(withIdentifier: segueID, sender: item)
            }
        } else if indexPath.section == 1 && !recentHistory.isEmpty {
            performSegue(withIdentifier: "viewConvoCell", sender: recentHistory[indexPath.row])
        }
    }

    // MARK: - Queue Deletion & Edit (Swipe for Quick Actions)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 0 && !quickActions.isEmpty else { return nil }
        let item = quickActions[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            self?.performQueueDeletion(for: 0, at: indexPath)
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
    
    private func showRenameAlert(for item: RoutineConversation, row: Int) {
        let alert = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = item.conversationTopic }
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            var updatedItem = item
            updatedItem.conversationTopic = newName
            QuickActionsRepository.shared.updateAction(updatedItem)
            
            self.quickActions[row] = updatedItem
            self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Queue Deletion (Context Menu for History)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.section == 1 && !recentHistory.isEmpty else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.showDeleteConfirmation(for: indexPath)
            }
            return UIMenu(title: "", children: [delete])
        }
    }

    func showDeleteConfirmation(for indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Conversation?", message: "This action cannot be undone.", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.performQueueDeletion(for: 1, at: indexPath)
        }
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
