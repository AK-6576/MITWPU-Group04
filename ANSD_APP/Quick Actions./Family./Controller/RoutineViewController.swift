//
//  RoutineViewController1.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 27/11/25.
//

import UIKit

class RoutineViewController1: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var routineList: [FamilyRoutineItem] = []
    var originalList: [FamilyRoutineItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        setupTableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.contentInset = .zero
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.separatorStyle = .singleLine
        loadData()
        setupNavigationBarMenu()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.tableFooterView = UIView()
    }
    
    func loadData() {
        self.routineList = RoutineRepository1.getMockData1()
        self.originalList = self.routineList
        tableView.reloadData()
    }
    
    func setupNavigationBarMenu() {
        let selectAction = UIAction(title: "Select Conversations", image: UIImage(systemName: "checkmark.circle")) { [weak self] _ in
            guard let self = self else { return }
            let isEditing = !self.tableView.isEditing
            self.tableView.setEditing(isEditing, animated: true)
        }
        
        let sortCustom = UIAction(title: "Custom (Reset)", image: UIImage(systemName: "arrow.counterclockwise"), state: .on) { [weak self] _ in
            guard let self = self else { return }
            self.routineList = self.originalList
            self.tableView.reloadData()
        }
        
        let sortTitle = UIAction(title: "Title (A-Z)", image: UIImage(systemName: "textformat")) { [weak self] _ in
            guard let self = self else { return }
            self.routineList.sort { $0.title < $1.title }
            self.tableView.reloadData()
        }
        
        let sortTime = UIAction(title: "Time", image: UIImage(systemName: "clock")) { [weak self] _ in
            guard let self = self else { return }
            self.routineList.sort { $0.time < $1.time }
            self.tableView.reloadData()
        }
        
        let sortNewest = UIAction(title: "Newest First", image: UIImage(systemName: "arrow.up")) { [weak self] _ in
            guard let self = self else { return }
            self.routineList = self.originalList.reversed()
            self.tableView.reloadData()
        }
        
        let sortByMenu = UIMenu(title: "Sort By", image: UIImage(systemName: "arrow.up.arrow.down"), children: [
            sortCustom, sortTitle, sortTime, sortNewest
        ])
        
        let groupAction = UIAction(title: "Group By Date", image: UIImage(systemName: "calendar")) { _ in
            print("Group By Date tapped")
        }
        
        let mainMenu = UIMenu(title: "", children: [selectAction, sortByMenu, groupAction])
        
        if let rightButton = navigationItem.rightBarButtonItem {
            rightButton.menu = mainMenu
        }
    }
    
    @objc private func didTapInfoButton(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowInfo", sender: sender.tag)
    }
    
    // MARK: - Updated Segue Logic (Half-Modal)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowInfo" {
            
            if let sheet = segue.destination.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routineList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath) as? RoutineTableViewCell1 else {
            return UITableViewCell()
        }
        
        let item = routineList[indexPath.row]
        cell.titleLabel.text = item.title
        cell.subtitleLabel.text = item.time
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            routineList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

