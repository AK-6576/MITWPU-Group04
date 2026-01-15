//
//  HomeViewController.swift
//  ANSD_APP
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    var quickActions: [RoutineConversation] = []
    var routineConversations: [RoutineConversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        navigationItem.hidesBackButton = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        // Remove extra system padding above headers
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
    }

    func loadData() {
        // Filter out "Done" items
        let allItems = QuickActionsRepository.shared.getAllActions().filter { $0.status != "Done" }

        self.routineConversations = Array(allItems.prefix(2))
        self.quickActions = Array(allItems.dropFirst(2))
        
        self.tableView.reloadData()
    }

    // MARK: - Actions (Profile / Footer Buttons)
    
    @IBAction func didTapNewConversation(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showNewConversation", sender: self)
    }

    @IBAction func didTapJoinConversation(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "showJoinConversation", sender: self)
    }

    @IBAction func didTapQuickCaption(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "Test1", sender: self)
    }
    
    // MARK: - Navigation Preparation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Note: Header button segues ("showQuickActions" and "viewConvo") are handled automatically by Storyboard.
        // They fall through this function without needing specific code.
        
        if segue.identifier == "showProfile" {
            let _ = (segue.destination as? UINavigationController)?.viewControllers.first as? ProfileTableViewController ?? segue.destination as? ProfileTableViewController
        }
        else if segue.identifier == "viewConvoCell" {
            // This handles tapping a Conversation Card row
            guard let destVC = segue.destination as? ChatHistory2ViewController,
                  let selectedItem = sender as? RoutineConversation else { return }
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
    
    // MARK: - Header Configuration
    // This connects your code to the Storyboard Header Cells
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let cellID = (section == 0) ? "QAHeaderCell" : "VCHeaderCell"
        
        // 2. Dequeue the cell
        guard let header = tableView.dequeueReusableCell(withIdentifier: cellID) as? HeaderCells else {
            return nil
        }
        
        // 3. Configure the Text
        if section == 0 {
            header.titleLabel.text = "Quick Actions"
            header.subtitleLabel?.text = "Upcoming"
        } else {
            header.titleLabel.text = "View Conversations"
        }
        
        return header.contentView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0) ? 70 : 50
    }
    
    // MARK: - Row Configuration
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "routineCell", for: indexPath) as? RoutineTableViewCell else { return UITableViewCell() }
            let item = quickActions[indexPath.row]
            let isLastRow = indexPath.row == quickActions.count - 1
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
            case "Friends": segueID = "family"
            default: return
            }
        } else {
            segueID = "viewConvoCell"
        }
        performSegue(withIdentifier: segueID, sender: item)
    }
    
    func presentInfoScreen(for item: RoutineConversation) {
        let alert = UIAlertController(title: item.conversationTopic, message: item.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
