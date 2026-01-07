//
//  HomeViewController.swift
//  Group_4-ANSD_App
//
//  Created by Daiwiik Harihar on 10/12/25.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileIconButton: UIButton!
    
    var quickActions: [RoutineConversation] = []
    var routineConversations: [RoutineConversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadQuickActionsData()
        navigationItem.hidesBackButton = true
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = UIView()
        tableView.layoutMargins = .zero
        tableView.separatorInset = .zero
        tableView.contentInset = .zero
    }

    func loadQuickActionsData() {
        let allItems = QuickActionsRepository.getAllActions()
        self.quickActions = Array(allItems.prefix(4))
        self.routineConversations = Array(allItems.dropFirst(4))
        self.tableView.reloadData()
    }
    
    @objc func headerChevronTapped(_ sender: UIButton) {
        if sender.tag == 0 {
            print("⚡️ 'Quick Actions' Header Chevron Tapped")
            performSegue(withIdentifier: "showQuickActions", sender: self)
        } else if sender.tag == 1 {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProfile" {
            var destinationVC: ProfileTableViewController?
            
            if let navigationController = segue.destination as? UINavigationController {
                destinationVC = navigationController.viewControllers.first as? ProfileTableViewController
            } else {
                destinationVC = segue.destination as? ProfileTableViewController
            }
            
            if let profileVC = destinationVC {
                profileVC.incomingName = usernameLabel?.text
                profileVC.incomingImage = profileIconButton?.image(for: .normal)
            }
        }
        
        if segue.identifier == "startCaptionSession" {
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return quickActions.count }
        return routineConversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as? RoutineTableViewCell else {
                return UITableViewCell()
            }
            
            let item = quickActions[indexPath.row]
            cell.configure(with: item)
            
            cell.onInfoTapped = { [weak self] in
                self?.presentInfoScreen(for: item)
            }
            
            cell.layoutMargins = .zero
            cell.preservesSuperviewLayoutMargins = false
            
            let totalRows = tableView.numberOfRows(inSection: indexPath.section)
            if indexPath.row == totalRows - 1 {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            } else {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            }
            
            return cell
        } else {
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section != 0 {
            return nil
        }
        
        let item = self.quickActions[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            self.quickActions.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (action, view, completionHandler) in
            self?.showRenameAlert(for: item, at: indexPath)
            completionHandler(true)
        }
        renameAction.backgroundColor = .systemOrange
        renameAction.image = UIImage(systemName: "pencil")
        
        let infoAction = UIContextualAction(style: .normal, title: "Info") { [weak self] (action, view, completionHandler) in
            self?.presentInfoScreen(for: item)
            completionHandler(true)
        }
        infoAction.backgroundColor = .systemBlue
        infoAction.image = UIImage(systemName: "info.circle")
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction, renameAction, infoAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    func showRenameAlert(for item: RoutineConversation, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Rename Action", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = item.conversationTopic
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            var updatedItem = item
            updatedItem.conversationTopic = newName
            self.quickActions[indexPath.row] = updatedItem
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func presentInfoScreen(for item: RoutineConversation) {
        let message = randomInfoMessage(for: item)

        let alert = UIAlertController(title: item.conversationTopic,
                                      message: message,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
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
extension HomeViewController {
    func randomInfoMessage(for item: RoutineConversation) -> String {
        // Try to build a pretty date string
        let prettyDate: String? = {
            guard let dateString = item.date else { return nil }
            let input = DateFormatter()
            input.dateFormat = "yyyy-MM-dd"
            input.locale = Locale.current
            input.timeZone = TimeZone.current

            let output = DateFormatter()
            output.dateStyle = .medium
            output.timeStyle = .none

            if let date = input.date(from: dateString) {
                return output.string(from: date)
            }
            return nil
        }()

        // Generate random end time
        let endTime = randomEndTimeString(from: item.startTime) ?? "TBD"

        // Base line describing the room
        let aboutLine = "This room is all about \(item.conversationTopic)."

        // Build a few rich templates
        var templates: [String] = []

        if let prettyDate = prettyDate {
            templates.append("""
            \(aboutLine)
            \(item.startTime) – \(endTime) on \(prettyDate).
            Status: \(item.status) in the \(item.categoryTitle) category.
            """)
            templates.append("""
            Welcome to "\(item.conversationTopic)" 🎙
            \(prettyDate) • \(item.startTime) → \(endTime)
            A quick space for your \(item.categoryTitle.lowercased()) updates.
            """)
            templates.append("""
            "\(item.conversationTopic)" is your dedicated \(item.categoryTitle.lowercased()) room.
            Kick-off: \(prettyDate), \(item.startTime) – \(endTime)
            Come prepared with key points and updates.
            """)
        } else {
            templates.append("""
            \(aboutLine)
            \(item.startTime) – \(endTime)
            Currently \(item.status.lowercased()) in the \(item.categoryTitle) category.
            Tap again any time to jump back in.
            """)
            templates.append("""
            "\(item.conversationTopic)" keeps your \(item.categoryTitle.lowercased()) moments organized.
            Status: \(item.status) • \(item.startTime) → \(endTime)
            Perfect for quick catch-ups and follow-throughs.
            """)
        }

        // If the model already has a description, prepend it sometimes
        if let desc = item.description, !desc.isEmpty {
            templates.append("""
            \(aboutLine)
            \(desc)
            \(item.startTime) – \(endTime) • \(item.status) • \(item.categoryTitle)
            """)
        }

        return templates.randomElement() ?? "This room keeps your conversation organized."
    }
}

extension HomeViewController {
    /// Returns a random end time 15–120 minutes after the given start time string.
    /// Expects startTime in "hh:mm a" format, e.g. "09:30 AM".
    func randomEndTimeString(from startTime: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale.current

        guard let startDate = formatter.date(from: startTime) else {
            return nil
        }

        // Random duration: 15–120 minutes
        let randomMinutes = Int.random(in: 15...120)
        let endDate = Calendar.current.date(
            byAdding: .minute,
            value: randomMinutes,
            to: startDate
        ) ?? startDate

        return formatter.string(from: endDate)
    }
}
