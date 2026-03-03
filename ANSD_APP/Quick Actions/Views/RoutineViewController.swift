//
//  RoutineViewController.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 05/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class BaseRoutineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var category: ChatCategory = .other
    var routineList: [RoutineItemProtocol] = []
    var originalList: [RoutineItemProtocol] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBarMenu()
        loadData()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 72
        tableView.tableFooterView = UIView()
    }
    
    func loadData() {
        // Fetch from Repository using the assigned category
        let data = RoutineRepository.getRoutineData(for: category)
        
        self.routineList = data
        self.originalList = data
        
        // Update UI Title
        self.title = "\(category.rawValue.capitalized) Routine"
        tableView.reloadData()
    }
    
    // MARK: - Menu Setup
    func setupNavigationBarMenu() {
     let sortTitle = UIAction(title: "Title (A-Z)", image: UIImage(systemName: "textformat")) { [weak self] _ in
            self?.routineList.sort { $0.title.lowercased() < $1.title.lowercased() }
            self?.tableView.reloadData()
        }
        
        let sortReset = UIAction(title: "Reset", image: UIImage(systemName: "arrow.counterclockwise")) { [weak self] _ in
            self?.routineList = self?.originalList ?? []
            self?.tableView.reloadData()
        }

        let sortByMenu = UIMenu(title: "Sort By", children: [sortTitle,sortReset ])
    
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "line.3.horizontal.decrease"),
                                                            target: nil, action: nil, menu: sortByMenu)
    }

    // MARK: - TableView Logic
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routineList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath) as? RoutineTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: routineList[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            self?.routineList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completion(true)
        }
        
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] (_, _, completion) in
            self?.showRenameAlert(at: indexPath)
            completion(true)
        }
        edit.backgroundColor = .systemOrange
        
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    
    private func showRenameAlert(at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Edit Title", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = self.routineList[indexPath.row].title }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self?.routineList[indexPath.row].title = newName
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowInfo",
           let nav = segue.destination as? UINavigationController,
           let destination = nav.topViewController as? InfoViewController,
           let indexPath = tableView.indexPathForSelectedRow {
            
            destination.existingNote = routineList[indexPath.row].notes
            destination.onSave = { [weak self] newNote in
                self?.routineList[indexPath.row].notes = newNote
                self?.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}

// MARK: - Storyboard Compatibility Aliases
typealias FamilyRoutineViewController = BaseRoutineViewController
typealias FriendsRoutineViewController = BaseRoutineViewController
typealias OfficeRoutineViewController = BaseRoutineViewController
typealias OtherRoutineViewController = BaseRoutineViewController
