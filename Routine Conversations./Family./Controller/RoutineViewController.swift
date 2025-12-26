//
//  RoutineViewController1.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 27/11/25.
//

import UIKit

class RoutineViewController1: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    // The Controller holds the data
    var routineList: [FamilyRoutineItem] = []
    
    // NEW: Backup list to restore original order
    var originalList: [FamilyRoutineItem] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Navigation Bar Setup
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // 2. Table View Setup
        setupTableView()
        
        // CRITICAL: This allows the cell to grow if text is large or padding is added
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        // Remove extra top/bottom padding and align separators
        tableView.contentInset = .zero
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.separatorStyle = .singleLine
        
        // 3. Load Data (Load before setting up menu so we have data to sort)
        loadData()
        
        // 4. Menu Setup
        setupNavigationBarMenu()
    }
    
    // MARK: - Setup Methods
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.cellLayoutMarginsFollowReadableWidth = false
        
        // Removes empty lines at bottom
        tableView.tableFooterView = UIView()
    }
    
    func loadData() {
        self.routineList = RoutineRepository1.getMockData1()
        // Save backup for "Custom (Reset)" sort
        self.originalList = self.routineList
        tableView.reloadData()
    }
    
    func setupNavigationBarMenu() {
        
        // --- ACTION 1: SELECT (Toggle Edit Mode) ---
        let selectAction = UIAction(title: "Select Conversations", image: UIImage(systemName: "checkmark.circle")) { [weak self] _ in
            guard let self = self else { return }
            let isEditing = !self.tableView.isEditing
            self.tableView.setEditing(isEditing, animated: true)
            print("Selection Mode Toggled: \(isEditing)")
        }
        
        // --- ACTION 2: SORT OPTIONS ---
        
        // Sort: Custom (Reset to original loaded order)
        let sortCustom = UIAction(title: "Custom (Reset)", image: UIImage(systemName: "arrow.counterclockwise"), state: .on) { [weak self] _ in
            guard let self = self else { return }
            self.routineList = self.originalList
            self.tableView.reloadData()
            print("Sorted: Custom (Reset)")
        }
        
        // Sort: Title (A-Z)
        let sortTitle = UIAction(title: "Title (A-Z)", image: UIImage(systemName: "textformat")) { [weak self] _ in
            guard let self = self else { return }
            self.routineList.sort { $0.title < $1.title }
            self.tableView.reloadData()
            print("Sorted: Title")
        }
        
        // Sort: Time (Ascending)
        let sortTime = UIAction(title: "Time", image: UIImage(systemName: "clock")) { [weak self] _ in
            guard let self = self else { return }
            self.routineList.sort { $0.time < $1.time }
            self.tableView.reloadData()
            print("Sorted: Time")
        }
        
        // Sort: Newest First (Reverses array as a proxy)
        let sortNewest = UIAction(title: "Newest First", image: UIImage(systemName: "arrow.up")) { [weak self] _ in
            guard let self = self else { return }
            self.routineList = self.originalList.reversed()
            self.tableView.reloadData()
            print("Sorted: Newest")
        }
        
        // Bundle them into Submenu
        let sortByMenu = UIMenu(title: "Sort By", image: UIImage(systemName: "arrow.up.arrow.down"), children: [
            sortCustom,
            sortTitle,
            sortTime,
            sortNewest
        ])
        
        // --- ACTION 3: GROUP ---
        let groupAction = UIAction(title: "Group By Date", image: UIImage(systemName: "calendar")) { _ in
            print("Group By Date tapped - Requires Section Logic Implementation")
        }
        
        // --- BUILD MENU ---
        let mainMenu = UIMenu(title: "", children: [
            selectAction,
            sortByMenu,
            groupAction
        ])
        
        // --- ATTACH TO BUTTON ---
        if let rightButton = navigationItem.rightBarButtonItem {
            rightButton.menu = mainMenu
        } else {
            // Fallback: If you didn't add the button in Storyboard, this creates it.
            let moreButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: mainMenu)
            navigationItem.rightBarButtonItem = moreButton
        }
    }
    
    // MARK: - Actions
    
    @objc private func didTapInfoButton(_ sender: UIButton) {
        // Send the Integer Tag (Row Index) as the sender object
        performSegue(withIdentifier: "ShowInfo", sender: sender.tag)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 1. Check Identifier
        if segue.identifier == "ShowInfo" {
            print("🟢 Segue 'ShowInfo' triggered!")
            
            // 2. Try to find the destination
            var destinationVC: InfoViewController1?
            
            if let nav = segue.destination as? UINavigationController {
                print("🔹 Destination is Navigation Controller")
                destinationVC = nav.topViewController as? InfoViewController1
            } else if let infoVC = segue.destination as? InfoViewController1 {
                print("🔹 Destination is directly InfoViewController")
                destinationVC = infoVC
            } else {
                print("🔴 ERROR: Could not find InfoViewController in destination!")
            }
            
            // 3. Pass the data
            if let infoVC = destinationVC, let rowIndex = sender as? Int {
                print("✅ Found InfoVC! Passing data for Row \(rowIndex)")
                
                // PASS DATA IN
                infoVC.existingNote = routineList[rowIndex].notes
                print("📤 Sent Note: '\(routineList[rowIndex].notes)'")
                
                // SETUP SAVE CLOSURE
                infoVC.onSave = { [weak self] newNote in
                    print("📥 RECEIVED back in RoutineVC: '\(newNote)'")
                    self?.routineList[rowIndex].notes = newNote
                }
            } else {
                print("🔴 ERROR: Row Index was missing or InfoVC is nil.")
            }
        }
    }
    
    // MARK: - Table View Data Source & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routineList.count
    }
    
    // Fix row height for consistent spacing
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    // Remove extra spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath) as? RoutineTableViewCell1 else {
            return UITableViewCell()
        }
        
        // 1. Setup Data
        let item = routineList[indexPath.row]
        cell.titleLabel.text = item.title
        cell.subtitleLabel.text = item.time
        
        // 2. Connect Custom Button
        cell.infoButton.tag = indexPath.row
        cell.infoButton.addTarget(self, action: #selector(didTapInfoButton(_:)), for: .touchUpInside)
        
        // 3. Style Cleanup
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        
        return cell
    }
    
    // MARK: - Editing Methods (Required for "Select Conversations" logic)
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Update Data Source
            routineList.remove(at: indexPath.row)
            // Update View
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
