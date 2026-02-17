//
//  AddActionTableViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 05/1/26.

import UIKit
protocol AddActionDelegate: AnyObject {
    func didCreateNewAction(_ action: RoutineConversation)
}

class AddActionTableViewController: UITableViewController, ParticipantsSelectionDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var participantsLabel: UILabel!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var daysCell: UITableViewCell!
    @IBOutlet weak var categoryCell: UITableViewCell!
    
    weak var delegate: AddActionDelegate?
    private var dayPopupButton: UIButton?
    private var categoryPopupButton: UIButton?
    
    var selectedCategory: String = "Office"
    var selectedDays: Set<String> = ["Monday"]
    var selectedParticipants: [String] = []
    
    var availableCategories: [String] = ["Friends", "Family", "Office"]
    let allDaysOrdered = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    // Function - Initializes the view lifecycle, setting up keyboard dismissal, default label states, and configuring cell menus.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardDismissal()
        participantsLabel.text = "None"
        saveButton.isEnabled = false
        setupDayCell()
        setupCategoryCell()
        nameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    // MARK: - Day Selection Setup
    
    // Function - Configures the day selection cell by creating a popup button and populating it with the menu options.
    private func setupDayCell() {
        dayPopupButton = createPopupButton()
        dayPopupButton?.tintColor = .systemBlue
        if var config = dayPopupButton?.configuration {
            config.baseForegroundColor = .label
            dayPopupButton?.configuration = config
        }
        updateDayMenu()
        daysCell.accessoryView = dayPopupButton
    }
    
    // Function - Rebuilds the day selection menu with checkboxes reflecting the current selection state.
    private func updateDayMenu() {
        var actions: [UIAction] = []
        for day in allDaysOrdered {
            let isSelected = selectedDays.contains(day)
            let action = UIAction(title: day, attributes: [.keepsMenuPresented], state: isSelected ? .on : .off) { [weak self] sender in
                self?.toggleDay(sender.title)
                sender.state = (self?.selectedDays.contains(sender.title) ?? false) ? .on : .off
                self?.updateDayButtonText()
                self?.updateDayMenu()
            }
            actions.append(action)
        }
        let menu = UIMenu(title: "Select Days", children: actions)
        dayPopupButton?.menu = menu
        updateDayButtonText()
    }
    
    // Function - Toggles the selection state of a specific day, preventing deselection if it is the last remaining day.
    private func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            if selectedDays.count > 1 { selectedDays.remove(day) }
        } else {
            selectedDays.insert(day)
        }
    }
    
    // Function - Updates the day button's title to display the formatted string of selected days.
    private func updateDayButtonText() {
        dayPopupButton?.configuration?.title = getFormattedDateString()
    }

    // MARK: - Category Selection Setup
    
    // Function - Configures the category selection cell by initializing the popup button and setting up its menu.
    private func setupCategoryCell() {
        categoryPopupButton = createPopupButton()
        setupCategoryMenu()
        categoryCell.accessoryView = categoryPopupButton
        updateCategory(selectedCategory)
    }
    
    // Function - Creates the menu for category selection, including predefined options and a custom creation action.
    private func setupCategoryMenu() {
        let selectionHandler: (UIAction) -> Void = { [weak self] action in
            self?.updateCategory(action.title)
        }
        
        var actions: [UIAction] = []
        for cat in availableCategories {
            let iconName = getSymbolForCategory(cat)
            let color = getColorForCategory(cat)
            let coloredImage = UIImage(systemName: iconName)?.withTintColor(color, renderingMode: .alwaysOriginal)
            
            let action = UIAction(title: cat, image: coloredImage, state: (cat == selectedCategory) ? .on : .off, handler: selectionHandler)
            actions.append(action)
        }
        
        let plusImage = UIImage(systemName: "plus")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        let createOwnAction = UIAction(title: "Create Own...", image: plusImage) { [weak self] _ in
            self?.showCustomCategoryAlert()
        }
        
        let menu = UIMenu(title: "Choose Category", children: actions + [createOwnAction])
        categoryPopupButton?.menu = menu
    }
    
    // Function - Updates the selected category variable and refreshes the button's appearance with the corresponding icon and color.
    private func updateCategory(_ category: String) {
        self.selectedCategory = category
        let iconName = getSymbolForCategory(category)
        let color = getColorForCategory(category)
        
        if var config = categoryPopupButton?.configuration {
            config.baseForegroundColor = .label
            config.title = category
            let symbolConfig = UIImage.SymbolConfiguration(scale: .medium)
            let coloredImage = UIImage(systemName: iconName, withConfiguration: symbolConfig)?
                .withTintColor(color, renderingMode: .alwaysOriginal)
            config.image = coloredImage
            config.imagePadding = 8
            categoryPopupButton?.configuration = config
        }
    }
    
    // MARK: - Helper Methods
    
    // Function - Creates and configures a standard UIButton with a trailing chevron image to indicate a dropdown menu.
    private func createPopupButton() -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.up.chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.titleLineBreakMode = .byTruncatingTail
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 35)
        button.contentHorizontalAlignment = .trailing
        return button
    }
    
    // Function - Generates a human-readable string summarizing the selected days (e.g., "Every Weekend", "Mon, Wed").
    private func getFormattedDateString() -> String {
        let weekdays: Set<String> = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        let weekends: Set<String> = ["Saturday", "Sunday"]
        if selectedDays.isEmpty { return "Select" }
        if selectedDays.count == 7 { return "Every Day" }
        if selectedDays == weekdays { return "Every Weekday" }
        if selectedDays == weekends { return "Every Weekend" }
        let sorted = allDaysOrdered.filter { selectedDays.contains($0) }
        return sorted.map { String($0.prefix(3)) }.joined(separator: ", ")
    }
    
    // Function - Displays an alert with a text field allowing the user to add a new custom category.
    private func showCustomCategoryAlert() {
        let alert = UIAlertController(title: "New Category", message: "Enter category name", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Category Name"; $0.autocapitalizationType = .words }
        let add = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self, let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            if !self.availableCategories.contains(text) { self.availableCategories.append(text) }
            self.updateCategory(text)
            self.setupCategoryMenu()
        }
        alert.addAction(add)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Save Action
    
    // Function - Validates the input, constructs a new routine conversation object, and notifies the delegate to save it.
    @IBAction func didTapSaveButton(_ sender: UIBarButtonItem) {
        guard let name = nameTextField.text, !name.isEmpty else { return }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            let timeString = formatter.string(from: startTimePicker.date)
        
        let iconName = getSymbolForCategory(selectedCategory)
        let dateString = getFormattedDateString()
        
        let newAction = RoutineConversation(
            id: UUID().uuidString,
            iconName: iconName,
            categoryTitle: selectedCategory,
            status: "Scheduled",
            conversationTopic: name,
            topicImage: "mic.circle.fill",
            startTime: timeString,
            description: selectedParticipants.isEmpty ? "No participants" : "With: \(selectedParticipants.joined(separator: ", "))",
            date: dateString,
            timeImage: "clock"
        )
        delegate?.didCreateNewAction(newAction)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Participants Selection
    
    // Function - Handles row selection events, specifically triggering the participants modal when the participants cell is tapped.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 1 { openParticipantsModal() }
    }
    
    // Function - Instantiates the participants view controller and presents it as a medium-detent sheet.
    private func openParticipantsModal() {
        let pickerVC = ParticipantsViewController()
        pickerVC.delegate = self
        pickerVC.initialSelectedNames = self.selectedParticipants
        let nav = UINavigationController(rootViewController: pickerVC)
        if let sheet = nav.sheetPresentationController { sheet.detents = [.medium(), .large()] }
        present(nav, animated: true)
    }

    // Function - Delegate method that receives the selected names and updates the UI label accordingly.
    func didSelectParticipants(_ names: [String]) {
        self.selectedParticipants = names
        participantsLabel.text = names.isEmpty ? "None" : names.joined(separator: ", ")
        participantsLabel.textColor = names.isEmpty ? .secondaryLabel : .label
    }
    
    // MARK: - Keyboard & Validation
    
    // Function - Adds a tap gesture recognizer to the view to dismiss the keyboard when tapping outside.
    private func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    // Function - Resigns the first responder status to close the keyboard.
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // Function - Monitors text changes in the name field to enable or disable the save button based on input validity.
    @objc private func textDidChange(_ sender: UITextField) {
        saveButton.isEnabled = !(sender.text?.isEmpty ?? true)
    }
}
