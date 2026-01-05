//
//  AddActionTableViewController.swift
//  ANSD_APP
//
//  Created by SDC-USER on 05/01/26.
//

import UIKit

protocol AddActionDelegate: AnyObject {
    func didCreateNewAction(_ action: RoutineConversation)
}

class AddActionTableViewController: UITableViewController {

    // MARK: - Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var participantsLabel: UILabel!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    
    // NEW: Connect this to the button in the "Days" row
    @IBOutlet weak var dayButton: UIButton!
    
    // Connect this to the button in the "Category" row
    @IBOutlet weak var categoryButton: UIButton!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // MARK: - Variables
    weak var delegate: AddActionDelegate?
    
    // Data holding
    var selectedCategory: String = "Office" // Default
    var selectedDay: String = "Monday"      // Default
    var selectedParticipants: [String] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupKeyboardDismissal()
        
        // Initial State
        participantsLabel.text = "None"
        saveButton.isEnabled = false
        
        // Setup the Pop-up Menus
        setupCategoryMenu()
        setupDayMenu()          // <--- New Function
        
        // Input Listeners
        nameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    // MARK: - 1. Setup Day Menu (Sunday - Saturday)
    func setupDayMenu() {
        let selectionHandler: (UIAction) -> Void = { [weak self] action in
            self?.updateDay(action.title)
        }
        
        // Create actions for every day of the week
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var actions: [UIAction] = []
        
        for day in days {
            let action = UIAction(title: day, handler: selectionHandler)
            actions.append(action)
        }
        
        // Create Menu
        let menu = UIMenu(title: "Select Day", children: actions)
        
        // Attach to Button
        dayButton.menu = menu
        dayButton.showsMenuAsPrimaryAction = true
        dayButton.changesSelectionAsPrimaryAction = true // Auto-updates the button text!
        
        // Set Default
        updateDay("Monday")
    }
    
    func updateDay(_ day: String) {
        self.selectedDay = day
        // Note: 'changesSelectionAsPrimaryAction = true' handles the button text,
        // but we store the value here for saving later.
    }
    
    // MARK: - 2. Setup Category Menu
    func setupCategoryMenu() {
        let selectionHandler: (UIAction) -> Void = { [weak self] action in
            self?.updateCategory(action.title)
        }
        
        let actions = [
            UIAction(title: "Friends", image: UIImage(systemName: "person.2.fill"), handler: selectionHandler),
            UIAction(title: "Family", image: UIImage(systemName: "house.fill"), handler: selectionHandler),
            UIAction(title: "Office", image: UIImage(systemName: "briefcase.fill"), handler: selectionHandler),
            UIAction(title: "Medical", image: UIImage(systemName: "cross.case.fill"), handler: selectionHandler),
            
            UIAction(title: "Create Own...", image: UIImage(systemName: "plus"), attributes: .destructive, handler: { [weak self] _ in
                self?.showCustomCategoryAlert()
            })
        ]
        
        let menu = UIMenu(title: "Choose Category", children: actions)
        
        categoryButton.menu = menu
        categoryButton.showsMenuAsPrimaryAction = true
        categoryButton.changesSelectionAsPrimaryAction = true
        
        updateCategory("Office")
    }
    
    func updateCategory(_ category: String) {
        self.selectedCategory = category
    }
    
    // MARK: - Custom Category Fallback
    func showCustomCategoryAlert() {
        let alert = UIAlertController(title: "New Category", message: "Enter category name", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Category Name" }
        
        let add = UIAlertAction(title: "Add", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                // Manually update title since "Create Own" was selected
                self.categoryButton.setTitle(text, for: .normal)
                self.updateCategory(text)
            }
        }
        alert.addAction(add)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Table View Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Only Section 1 needs a tap (for Participants Segue)
        // Days and Categories are now Buttons, so we don't handle their taps here.
        if indexPath.section == 1 {
            performSegue(withIdentifier: "showParticipantsModal", sender: self)
        }
    }

    // MARK: - Save Action
    @IBAction func didTapSaveButton(_ sender: UIBarButtonItem) {
        guard let name = nameTextField.text, !name.isEmpty else { return }
        
        // Format Time
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: startTimePicker.date)
        
        // Icon Logic
        let iconName: String
        switch selectedCategory.lowercased() {
        case "friends": iconName = "person.2.fill"
        case "family": iconName = "house.fill"
        case "medical", "health": iconName = "cross.case.fill"
        default: iconName = "briefcase.fill"
        }
        
        // Create Model
        let newAction = RoutineConversation(
            id: UUID().uuidString,
            iconName: iconName,
            categoryTitle: selectedCategory,
            status: "Scheduled",
            conversationTopic: name,
            topicImage: "mic.circle.fill",
            timeRange: timeString,       // e.g., "10:30 AM"
            description: selectedParticipants.isEmpty ? "No participants" : "With: \(selectedParticipants.joined(separator: ", "))",
            date: selectedDay,           // <--- Uses the selected Day (e.g., "Monday")
            timeImage: "clock"
        )
        
        delegate?.didCreateNewAction(newAction)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Utilities
    func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func textDidChange(_ sender: UITextField) {
        saveButton.isEnabled = !(sender.text?.isEmpty ?? true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showParticipantsModal" {
            // Segue logic
        }
    }
}
