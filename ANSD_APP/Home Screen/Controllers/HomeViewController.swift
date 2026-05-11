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
import TipKit

class HomeViewController: UIViewController {
    
    // MARK: - Outlets & Properties
    @IBOutlet weak var tableView: UITableView!

    var quickActions: [RoutineConversation] = []
    var recentHistory: [Conversation] = []
    
    private let profileButton = UIButton(type: .custom)

    // MARK: - TipKit
    // Tip instances (one per UI feature on the Home Screen)
    private let profileTip         = ProfileButtonTip()
    private let quickActionsTip    = QuickActionsTip()
    private let newConvoTip        = NewConversationTip()
    private let joinConvoTip       = JoinConversationTip()
    private let viewConvosTip      = ViewConversationsTip()

    /// Flag: tips have been presented for this installation
    private static let tipsShownKey = "home_tips_shown_v1"
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupProfileButton()
        loadSavedProfileImage()
        configureTipKit()      // ← TipKit: configure once per install
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        if let headerView = tableView.tableHeaderView as? GreetingViewCell {
            headerView.helloLabel.isHidden = false
        }
        
        navigationItem.title = ""
        navigationItem.hidesBackButton = true
        
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Wait for notification authorization before potentially showing tips.
        // This ensures the tips don't appear in the background while the OS permission alert is up.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.presentHomeTipsIfNeeded()
            }
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
                        chatVC.participantNames = selectedItem.participantNames ?? []
                        chatVC.hostUID = selectedItem.hostUID
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

    // MARK: - TipKit Configuration & Presentation

    /// Call once at app launch to configure the TipKit data store.
    private func configureTipKit() {
        do {
            // In production: Tips.configure()
            // During development/testing you can use:
            // try Tips.resetDatastore()           // ← uncomment to reset tips during QA
            // try Tips.configure([.displayFrequency(.immediate)])  // ← show all tips immediately for testing
            try Tips.configure()
        } catch {
            print("HomeTips: TipKit configuration failed — \(error)")
        }
    }

    /// Presents the ordered tip sequence only on the user's first session after account creation.
    /// The flag `home_tips_shown_v1` is written by `VoiceCalibrationViewController` immediately
    /// before navigating here, so tips fire exactly once, on first arrival at Home.
    private func presentHomeTipsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.tipsShownKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.tipsShownKey)

        // Present tips as a sequenced popover walk-through with a short delay between each.
        Task { @MainActor in
            // 1. Profile button tip — anchor to the nav-bar right button
            if let barItem = navigationItem.rightBarButtonItem,
               let anchorView = barItem.customView {
                let profilePopover = TipUIPopoverViewController(profileTip, sourceItem: anchorView)
                profilePopover.view.tintColor = .systemIndigo
                present(profilePopover, animated: true)
                try? await Task.sleep(for: .seconds(3.5))
                profilePopover.dismiss(animated: true)
            }

            try? await Task.sleep(for: .seconds(0.4))

            // 2. New & Join Conversation tips — anchor to the specific views in the header
            if let headerView = tableView.tableHeaderView as? GreetingViewCell {
                if let newConvoView = headerView.newConvoView {
                    let newConvoPopover = TipUIPopoverViewController(newConvoTip, sourceItem: newConvoView)
                    newConvoPopover.view.tintColor = .systemBlue
                    present(newConvoPopover, animated: true)
                    try? await Task.sleep(for: .seconds(3.5))
                    newConvoPopover.dismiss(animated: true)
                }
                
                try? await Task.sleep(for: .seconds(0.4))
                
                if let joinConvoView = headerView.joinConvoView {
                    let joinConvoPopover = TipUIPopoverViewController(joinConvoTip, sourceItem: joinConvoView)
                    joinConvoPopover.view.tintColor = .systemIndigo
                    present(joinConvoPopover, animated: true)
                    try? await Task.sleep(for: .seconds(3.5))
                    joinConvoPopover.dismiss(animated: true)
                }
            }

            try? await Task.sleep(for: .seconds(0.4))

            // 3. Quick Actions tip — anchored to the section 0 header
            let qaPopover = TipUIPopoverViewController(quickActionsTip, sourceItem: tableView)
            qaPopover.popoverPresentationController?.sourceRect = tableView.rectForHeader(inSection: 0)
            qaPopover.view.tintColor = .systemOrange
            present(qaPopover, animated: true)
            try? await Task.sleep(for: .seconds(3.5))
            qaPopover.dismiss(animated: true)

            try? await Task.sleep(for: .seconds(0.4))

            // 4. View Conversations tip — anchored to the section 1 header
            let vcPopover = TipUIPopoverViewController(viewConvosTip, sourceItem: tableView)
            vcPopover.popoverPresentationController?.sourceRect = tableView.rectForHeader(inSection: 1)
            vcPopover.view.tintColor = .systemTeal
            present(vcPopover, animated: true)
            try? await Task.sleep(for: .seconds(3.5))
            vcPopover.dismiss(animated: true)
        }
    }

    // MARK: - (Debug / QA) Reset Tips — call from Settings screen to replay the tip tour
    static func resetTips() {
        UserDefaults.standard.set(false, forKey: tipsShownKey)
        try? Tips.resetDatastore()
    }
    
}

// MARK: - TableView Delegate & DataSource (RESTORED HEADERS)
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return quickActions.count >= 3 ? 3 : quickActions.count + 1
        } else {
            return recentHistory.isEmpty ? 1 : recentHistory.count
        }
    }

    // RESTORED: Heading Labels Logic
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cellID = (section == 0) ? "QAHeaderCell" : "VCHeaderCell"
        guard let header = tableView.dequeueReusableCell(withIdentifier: cellID) as? HeaderCells else { return nil }
        
        // Failsafe for disconnected Storyboard Outlets
        if header.titleLabel != nil {
            header.titleLabel.text = (section == 0) ? "Quick Actions" : "View Conversations"
            header.subtitleLabel?.text = (section == 0) ? "Upcoming" : ""
        } else {
            // Programmatic fallback
            header.contentView.subviews.forEach { $0.removeFromSuperview() } // Clear broken IB elements
            
            let titleLbl = UILabel()
            titleLbl.text = (section == 0) ? "Quick Actions" : "View Conversations"
            titleLbl.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            titleLbl.translatesAutoresizingMaskIntoConstraints = false
            header.contentView.addSubview(titleLbl)
            
            NSLayoutConstraint.activate([
                titleLbl.leadingAnchor.constraint(equalTo: header.contentView.leadingAnchor, constant: 16),
                titleLbl.centerYAnchor.constraint(equalTo: header.contentView.centerYAnchor)
            ])
            
            if section == 0 {
                let subLbl = UILabel()
                subLbl.text = "Upcoming"
                subLbl.font = UIFont.systemFont(ofSize: 15, weight: .regular)
                subLbl.textColor = .label
                subLbl.translatesAutoresizingMaskIntoConstraints = false
                header.contentView.addSubview(subLbl)
                
                NSLayoutConstraint.activate([
                    subLbl.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor, constant: 8),
                    subLbl.bottomAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: -2)
                ])
            }
        }
        
        return header.contentView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as? QuickActionTableViewCell else { return UITableViewCell() }
            
            let isAddRowVisible = quickActions.count < 3
            let isLast = (indexPath.row == (isAddRowVisible ? quickActions.count : 2))
            let isAddRow = isAddRowVisible && (indexPath.row == quickActions.count)
            let isFirst = (indexPath.row == 0)
            
            if isAddRow {
                cell.configure(with: nil, isFirst: isFirst, isLast: true, isAddRow: true)
            } else {
                let item = quickActions[indexPath.row]
                cell.configure(with: item, isFirst: isFirst, isLast: isLast, isAddRow: false)
            }
            return cell
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
        if indexPath.section == 0 {
            let isAddRowVisible = quickActions.count < 3
            if isAddRowVisible && indexPath.row == quickActions.count {
                if let addVC = self.storyboard?.instantiateViewController(withIdentifier: "AddCategoryVC") as? AddActionTableViewController {
                    let nav = UINavigationController(rootViewController: addVC)
                    self.present(nav, animated: true, completion: nil)
                }
            } else {
                let item = quickActions[indexPath.row]
                
                // ROLE-BASED NAVIGATION
                let currentUID = Auth.auth().currentUser?.uid
                if let host = item.hostUID, host != currentUID {
                    // I am a participant -> Push ActionJoinViewController directly from Action storyboard
                    // This ensures participants join the same room as the host without legacy generic join logic.
                    QuickActionAccess.verifyAccess(for: item, over: self) { [weak self] in
                        let storyboard = UIStoryboard(name: "Action", bundle: nil)
                        if let chatVC = storyboard.instantiateViewController(withIdentifier: "ActionNewViewController") as? ActionJoinViewController {
                            chatVC.sessionTitle = "\(item.conversationTopic) Session"
                            chatVC.category = item.categoryTitle
                            chatVC.roomCode = item.roomCode
                            chatVC.participantNames = item.participantNames ?? []
                            chatVC.hostUID = item.hostUID
                            self?.navigationController?.pushViewController(chatVC, animated: true)
                        }
                    }
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
            }
        } else if indexPath.section == 1 && !recentHistory.isEmpty {
            performSegue(withIdentifier: "viewConvoCell", sender: recentHistory[indexPath.row])
        }
    }

    // MARK: - Queue Deletion & Edit (Swipe for Quick Actions)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 0, indexPath.row < quickActions.count else { return nil }
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
