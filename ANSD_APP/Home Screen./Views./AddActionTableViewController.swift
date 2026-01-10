//
//  AddActionTableViewController.swift
//  ANSD_APP
//

import UIKit

protocol AddActionDelegate: AnyObject {
    func didCreateNewAction(_ action: RoutineConversation)
}

class AddActionTableViewController: UITableViewController, ParticipantsSelectionDelegate {

    // MARK: - Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var participantsLabel: UILabel!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var daysCell: UITableViewCell!
    @IBOutlet weak var categoryCell: UITableViewCell!
    
    // MARK: - Variables
    weak var delegate: AddActionDelegate?
    private var dayPopupButton: UIButton?
    private var categoryPopupButton: UIButton?
    
    var selectedCategory: String = "Office"
    var selectedDays: Set<String> = ["Monday"]
    var selectedParticipants: [String] = []
    
    var availableCategories: [String] = ["Friends", "Family", "Office"]
    let allDaysOrdered = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardDismissal()
        participantsLabel.text = "None"
        saveButton.isEnabled = false
        setupDayCell()
        setupCategoryCell()
        nameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    // MARK: - Days Drop-down
    func setupDayCell() {
        dayPopupButton = createPopupButton()
        dayPopupButton?.tintColor = .systemBlue
        if var config = dayPopupButton?.configuration {
            config.baseForegroundColor = .label
            dayPopupButton?.configuration = config
        }
        updateDayMenu()
        daysCell.accessoryView = dayPopupButton
    }
          
    func updateDayMenu() {
        var actions: [UIAction] = []
        for day in allDaysOrdered {
            let isSelected = selectedDays.contains(day)
            let action = UIAction(title: day, attributes: [.keepsMenuPresented], state: isSelected ? .on : .off) { [weak self] sender in
                self?.toggleDay(sender.title)
                sender.state = (self?.selectedDays.contains(sender.title) ?? false) ? .on : .off
                self?.updateDayButtonText()
                self!.updateDayMenu()
            }
            actions.append(action)
        }
        let menu = UIMenu(title: "Select Days", children: actions)
        dayPopupButton?.menu = menu
        updateDayButtonText()
    }
    
    func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            if selectedDays.count > 1 { selectedDays.remove(day) }
        } else {
            selectedDays.insert(day)
        }
    }
    
    func updateDayButtonText() {
        dayPopupButton?.configuration?.title = getFormattedDateString()
    }

    // MARK: - Category Drop-down
    func setupCategoryCell() {
        categoryPopupButton = createPopupButton()
        setupCategoryMenu()
        categoryCell.accessoryView = categoryPopupButton
        updateCategory(selectedCategory)
    }
       
    func setupCategoryMenu() {
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
    
    func updateCategory(_ category: String) {
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
    
    // MARK: - Helpers
    func createPopupButton() -> UIButton {
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
    
    func getFormattedDateString() -> String {
        let weekdays: Set<String> = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        let weekends: Set<String> = ["Saturday", "Sunday"]
        if selectedDays.isEmpty { return "Select" }
        if selectedDays.count == 7 { return "Every Day" }
        if selectedDays == weekdays { return "Every Weekday" }
        if selectedDays == weekends { return "Every Weekend" }
        let sorted = allDaysOrdered.filter { selectedDays.contains($0) }
        return sorted.map { String($0.prefix(3)) }.joined(separator: ", ")
    }
    
    func showCustomCategoryAlert() {
        let alert = UIAlertController(title: "New Category", message: "Enter category name", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Category Name"; $0.autocapitalizationType = .words }
        let add = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self, let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            if !self.availableCategories.contains(text) { self.availableCategories.append(text) }
            self.updateCategory(text)
            self.setupCategoryMenu()
        }
        alert.addAction(add); alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Save Action
    @IBAction func didTapSaveButton(_ sender: UIBarButtonItem) {
        guard let name = nameTextField.text, !name.isEmpty else { return }
        
        // --- KEY CHANGE: Strict Time Formatting for Sorting ---
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // e.g. "9:30 AM"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        let timeString = formatter.string(from: startTimePicker.date)
       
        let iconName = getSymbolForCategory(selectedCategory)
        let dateString = getFormattedDateString()
       
        let newAction = RoutineConversation(
            id: UUID().uuidString, iconName: iconName, categoryTitle: selectedCategory,
            status: "Scheduled", conversationTopic: name, topicImage: "mic.circle.fill",
            startTime: timeString,
            description: selectedParticipants.isEmpty ? "No participants" : "With: \(selectedParticipants.joined(separator: ", "))",
            date: dateString, timeImage: "clock"
        )
        delegate?.didCreateNewAction(newAction)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Participants
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 1 { openParticipantsModal() }
    }
    
    func openParticipantsModal() {
        let pickerVC = ParticipantsViewController()
        pickerVC.delegate = self
        pickerVC.initialSelectedNames = self.selectedParticipants
        let nav = UINavigationController(rootViewController: pickerVC)
        if let sheet = nav.sheetPresentationController { sheet.detents = [.medium(), .large()] }
        present(nav, animated: true)
    }

    func didSelectParticipants(_ names: [String]) {
        self.selectedParticipants = names
        participantsLabel.text = names.isEmpty ? "None" : names.joined(separator: ", ")
        participantsLabel.textColor = names.isEmpty ? .secondaryLabel : .label
    }
    
    // MARK: - Utilities
    func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false; view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() { view.endEditing(true) }
    @objc func textDidChange(_ sender: UITextField) { saveButton.isEnabled = !(sender.text?.isEmpty ?? true) }
}
