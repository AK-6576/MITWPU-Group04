//
//  SessionSelectionViewController.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 01/12/25.
//

import UIKit

class SessionSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var GJtableView: UITableView!
    
    let sessions: [GroupJoinSessionModel] = [
        GroupJoinSessionModel(title: "UI/UX Design Session", subtitle: "Reed Richards"),
        GroupJoinSessionModel(title: "Project Alpha X7", subtitle: "Bruce Wayne"),
        GroupJoinSessionModel(title: "Starbucks Meetup", subtitle: "Andrew Garfield"),
        GroupJoinSessionModel(title: "Assignment Completion", subtitle: "Peter Parker")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    func setupTableView() {
        GJtableView.delegate = self
        GJtableView.dataSource = self
        GJtableView.backgroundColor = .systemGroupedBackground
        GJtableView.tableFooterView = UIView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat" {
            if let chatVC = segue.destination as? GroupJoinViewController {
                chatVC.modalPresentationStyle = .fullScreen
                if let sessionData = sender as? GroupJoinSessionModel {
                    chatVC.title = sessionData.title
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGroupedBackground
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let session = sessions[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = session.title
        content.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        content.secondaryText = session.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSession = sessions[indexPath.row]
        performSegue(withIdentifier: "goToChat", sender: selectedSession)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
