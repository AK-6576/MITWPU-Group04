//
//  HomeViewController.swift
//  Group_4-ANSD_App
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
        loadData()
        navigationItem.hidesBackButton = true
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        // CRITICAL FIXES FOR CARD LOOK:
        tableView.backgroundColor = .systemGray6 // Gray background makes white cards pop
        tableView.separatorStyle = .none         // Removes lines between cards
        
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
    }

    func loadData() {
        let allItems = QuickActionsRepository.getAllActions()
        if allItems.count >= 4 {
            self.quickActions = Array(allItems.prefix(4))
            self.routineConversations = Array(allItems.dropFirst(4))
        } else {
            self.quickActions = allItems
            self.routineConversations = []
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Actions & Navigation (Unchanged)
    @objc func headerChevronTapped(_ sender: UIButton) {
        let segueID = (sender.tag == 0) ? "showQuickActions" : "viewConvo"
        performSegue(withIdentifier: segueID, sender: self)
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
            let destinationVC = (segue.destination as? UINavigationController)?.viewControllers.first as? ProfileTableViewController ?? segue.destination as? ProfileTableViewController
            destinationVC?.incomingName = "Hello + \(usernameLabel?.text)"
            destinationVC?.incomingImage = profileIconButton?.image(for: .normal)
        }
    }
}

// MARK: - TableView Delegate & DataSource
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0) ? quickActions.count : routineConversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // Section 0: Quick Actions (List Style)
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as? RoutineTableViewCell else { return UITableViewCell() }
            
            let item = quickActions[indexPath.row]
            // Pass isLast to hide the manual separator for the last item
            let isLast = indexPath.row == quickActions.count - 1
            cell.configure(with: item, isLast: isLast)
            
            cell.onInfoTapped = { [weak self] in self?.presentInfoScreen(for: item) }
            return cell
        } else {
            // Section 1: Conversations (Card Style)
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCardCell", for: indexPath) as? ConversationCardCell else { return UITableViewCell() }
            
            let item = routineConversations[indexPath.row]
            cell.configure(with: item)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = (indexPath.section == 0) ? quickActions[indexPath.row] : routineConversations[indexPath.row]
        let segueID = (indexPath.section == 0) ? "startCaptionSession" : "viewConvoCell"
        performSegue(withIdentifier: segueID, sender: item)
    }
    
    // MARK: - Headers
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        // Make header background clear to match the gray table background
        headerView.backgroundColor = .clear
        
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
        return 50
    }
    
    // Helper for Info Alert
    func presentInfoScreen(for item: RoutineConversation) {
        let alert = UIAlertController(title: item.conversationTopic, message: "Details for \(item.conversationTopic)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
