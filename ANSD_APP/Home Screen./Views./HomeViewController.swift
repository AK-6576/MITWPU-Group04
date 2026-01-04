//
//  HomeViewController.swift
//  Group_4-ANSD_App
//
//  Created by Daiwiik Harihar on 10/12/25.
//

import UIKit

class HomeViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // IMPORTANT: Make sure this connects to the BUTTON inside the Bar Item, not the Bar Item itself.
    @IBOutlet weak var profileIconButton: UIButton!
    
    
    // MARK: - Data Models
    var quickActions: [RoutineConversation] = []       // Section 0
    var routineConversations: [RoutineConversation] = [] // Section 1
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadQuickActionsData()
        
        navigationItem.hidesBackButton = true
        
        // 1. LOAD SAVED NAME
        if let savedName = UserDefaults.standard.string(forKey: "savedUserName") {
            usernameLabel.text = savedName
        }
    }
    
    // MARK: - Setup
    func setupTableView() {
            tableView.delegate = self
            tableView.dataSource = self
            
            // 1. Fix top padding above Section Headers
            if #available(iOS 15.0, *) {
                tableView.sectionHeaderTopPadding = 0
            }
            
            // 2. Set Style
            tableView.separatorStyle = .singleLine
            
            // 3. Remove Empty Cell Separators at the bottom
            tableView.tableFooterView = UIView()
            
            // 4. "The Magic Lines": Reset global margins to remove unwanted gaps
            tableView.layoutMargins = .zero
            tableView.separatorInset = .zero
            tableView.contentInset = .zero
        }

    // MARK: - Data Loading
        func loadQuickActionsData() {
            // 1. Get all data from the repository
                    let allItems = QuickActionsRepository.getAllActions()
                    
                    // 2. Split the data
                    // First 4 items go to the "Quick Actions" section
                    self.quickActions = Array(allItems.prefix(4))
                    
                    // The rest go to the "View Conversations" section
                    self.routineConversations = Array(allItems.dropFirst(4))
                    
                    // 3. Refresh the table
                    self.tableView.reloadData()
        }
    
    // MARK: - Actions
        
        // This handles clicks on the chevron (>) button in the section headers
        @objc func headerChevronTapped(_ sender: UIButton) {
            
            // Tag 0 = Quick Actions Section (The top list)
            if sender.tag == 0 {
                print("⚡️ 'Quick Actions' Header Chevron Tapped")
                // This runs the manual segue you just created in Storyboard
                performSegue(withIdentifier: "showQuickActions", sender: self)
            }
            
            // Tag 1 = View Conversations Section (The bottom list)
            else if sender.tag == 1 {
                print("👉 'View Conversations' Header Chevron Tapped")
                performSegue(withIdentifier: "viewConvo", sender: self)
            }
        }
    
    @IBAction func didTapNewConversation(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showNewConversation", sender: self)
    }

    @IBAction func didTapJoinConversation(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showJoinConversation", sender: self)
    }

    @IBAction func didTapQuickCaption(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "Test1", sender: self)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            
            var destinationVC: ProfileTableViewController?
            
            // Handle if it's inside a Navigation Controller (Modal) or Direct Push
            if let navigationController = segue.destination as? UINavigationController {
                destinationVC = navigationController.viewControllers.first as? ProfileTableViewController
            } else {
                destinationVC = segue.destination as? ProfileTableViewController
            }
            
            if let profileVC = destinationVC {
                // Pass current data so the profile screen knows what to show
                profileVC.incomingName = usernameLabel?.text
                profileVC.incomingImage = profileIconButton?.image(for: .normal)
            }
        }
        
        if segue.identifier == "startCaptionSession" {
            // handle quick action
        }
    }
}

// MARK: - Table View Delegate & DataSource
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return quickActions.count }
        return routineConversations.count
    }
    
    // CORRECTED FUNCTION SIGNATURE
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            if indexPath.section == 0 {
                // --- QUICK ACTIONS SECTION ---
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as? RoutineTableViewCell else {
                    return UITableViewCell()
                }
                
                let item = quickActions[indexPath.row]
                
                // 1. Configure
                cell.configure(with: item)
                
                // 2. Info Button Action
                cell.onInfoTapped = { [weak self] in
                    self?.presentInfoScreen(for: item)
                }
                
                // 3. SEPARATOR LOGIC (Hides the line for the last row)
                // Reset cell margins first
                cell.layoutMargins = .zero
                cell.preservesSuperviewLayoutMargins = false
                
                let totalRows = tableView.numberOfRows(inSection: indexPath.section)
                if indexPath.row == totalRows - 1 {
                    // LAST ROW: Push the separator way off-screen to hide it
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                } else {
                    // OTHER ROWS: Standard indentation (20px from left)
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
                }
                
                return cell
                
            } else {
                // --- VIEW CONVERSATIONS SECTION ---
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCardCell", for: indexPath) as? ConversationCardCell else {
                    return UITableViewCell()
                }
                let item = routineConversations[indexPath.row]
                cell.configure(with: item)
                return cell
            }
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let item = quickActions[indexPath.row]
            performSegue(withIdentifier: "startCaptionSession", sender: item)
        } else {
            let item = routineConversations[indexPath.row]
            performSegue(withIdentifier: "pastConvoCell", sender: item)
        }
    }
    
    // MARK: - Swipe Actions (Quick Actions Section Only)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // 1. Only allow swipes in Section 0
        if indexPath.section != 0 {
            return nil
        }
        
        let item = self.quickActions[indexPath.row]
        
        // --- DELETE ACTION ---
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            // Remove from Data Source
            self.quickActions.remove(at: indexPath.row)
            
            // Remove from TableView
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // TODO: Update your actual Repository here if needed
            // QuickActionsRepository.delete(item)
            
            completionHandler(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        // --- RENAME ACTION ---
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (action, view, completionHandler) in
            self?.showRenameAlert(for: item, at: indexPath)
            completionHandler(true)
        }
        renameAction.backgroundColor = .systemOrange
        renameAction.image = UIImage(systemName: "pencil")
        
        // --- INFO ACTION ---
        let infoAction = UIContextualAction(style: .normal, title: "Info") { [weak self] (action, view, completionHandler) in
            self?.presentInfoScreen(for: item)
            completionHandler(true)
        }
        infoAction.backgroundColor = .systemBlue
        infoAction.image = UIImage(systemName: "info.circle")
        
        // Combine actions
        let config = UISwipeActionsConfiguration(actions: [deleteAction, renameAction, infoAction])
        config.performsFirstActionWithFullSwipe = false
        
        return config
    }
    
    // Helper for Rename
    func showRenameAlert(for item: RoutineConversation, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Rename Action", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = item.conversationTopic
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            
            // Update Local Data
            var updatedItem = item
            updatedItem.conversationTopic = newName
            self.quickActions[indexPath.row] = updatedItem
            
            // Update Row UI
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Info Screen Logic
        // This function runs whenever an (i) button is tapped
        func presentInfoScreen(for item: RoutineConversation) {
            
            // 1. Create a simple Alert (Popup)
            // We use the item's topic (e.g., "Scrum Meet") as the Title
            // We use the item's description (e.g., "Updates on Project...") as the Message
            let alert = UIAlertController(title: item.conversationTopic,
                                          message: item.description ?? "No details available.",
                                          preferredStyle: .alert)
            
            // 2. Add an "OK" button to close it
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // 3. Show it
            present(alert, animated: true)
        }
    
    
    
    
    // MARK: - Headers
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.text = (section == 0) ? "Quick Actions" : "View Conversations"
        
        let chevronButton = UIButton(type: .system)
        chevronButton.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        chevronButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        chevronButton.tintColor = .systemGray
        chevronButton.tag = section
        chevronButton.addTarget(self, action: #selector(headerChevronTapped(_:)), for: .touchUpInside)
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(chevronButton)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            chevronButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            chevronButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
}
