import UIKit

protocol AddActionDelegate: AnyObject {
    func didCreateNewAction(_ action: RoutineConversation)
}

class AddActionTableViewController: UITableViewController {

    // MARK: - Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var participantsLabel: UILabel!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIBarButtonItem!

    // Connect these to the Table View Cells in Storyboard
    @IBOutlet weak var daysCell: UITableViewCell!
    @IBOutlet weak var categoryCell: UITableViewCell!
    
    // References to our code-generated buttons
    private var dayPopupButton: UIButton?
    private var categoryPopupButton: UIButton?

    // MARK: - Variables
    weak var delegate: AddActionDelegate?
    
    // Data
    var selectedCategory: String = "Office"
    var selectedDays: Set<String> = ["Monday"]
    var selectedParticipants: [String] = []
    
    let allDaysOrdered = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupKeyboardDismissal()
        
        // Initial State
        participantsLabel.text = "None"
        saveButton.isEnabled = false
        
        // Setup Drop-downs
        setupDayCell()
        setupCategoryCell()
        
        // Input Listeners
        nameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    // MARK: - 1. Days Drop-down (Multi-Select)
    func setupDayCell() {
        dayPopupButton = createPopupButton(actionHandler: { [weak self] action in
            self?.toggleDay(action.title)
        })
        
        updateDayMenu()
        daysCell.accessoryView = dayPopupButton
    }
    
    func updateDayMenu() {
        let selectionHandler: (UIAction) -> Void = { [weak self] action in
            self?.toggleDay(action.title)
        }
        
        var actions: [UIAction] = []
        for day in allDaysOrdered {
            let isSelected = selectedDays.contains(day)
            let action = UIAction(title: day, state: isSelected ? .on : .off, handler: selectionHandler)
            actions.append(action)
        }
        
        let menu = UIMenu(title: "Select Days", options: .displayInline, children: actions)
        dayPopupButton?.menu = menu
        
        updateDayButtonText()
    }
    
    func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            if selectedDays.count > 1 { selectedDays.remove(day) }
        } else {
            selectedDays.insert(day)
        }
        updateDayMenu()
    }
    
    func updateDayButtonText() {
        let sortedDays = allDaysOrdered.filter { selectedDays.contains($0) }
        
        var title = "Select"
        if sortedDays.count == 7 {
            title = "Every Day"
        } else if !sortedDays.isEmpty {
            title = sortedDays.map { String($0.prefix(3)) }.joined(separator: ", ")
        }
        
        dayPopupButton?.configuration?.title = title
    }

    // MARK: - 2. Category Drop-down
    func setupCategoryCell() {
        categoryPopupButton = createPopupButton(actionHandler: { [weak self] action in
            self?.updateCategory(action.title)
        })
        
        setupCategoryMenu()
        categoryCell.accessoryView = categoryPopupButton
    }
    
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
        categoryPopupButton?.menu = menu
        
        categoryPopupButton?.configuration?.title = selectedCategory
    }
    
    func updateCategory(_ category: String) {
        self.selectedCategory = category
        categoryPopupButton?.configuration?.title = category
    }

    // MARK: - HELPER: Create Button (Plain Style)
    func createPopupButton(actionHandler: @escaping UIActionHandler) -> UIButton {
        // CHANGED: Use .plain() instead of .tinted() to remove the background box
        var config = UIButton.Configuration.plain()
        
        config.image = UIImage(systemName: "chevron.up.chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        
        // Optional: Force the text color to standard iOS blue if needed
        // config.baseForegroundColor = .systemBlue
        
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        
        // Sizing
        button.frame = CGRect(x: 0, y: 0, width: 140, height: 35)
        button.contentHorizontalAlignment = .trailing
        
        return button
    }
    
    // MARK: - Custom Alert
    func showCustomCategoryAlert() {
        let alert = UIAlertController(title: "New Category", message: "Enter category name", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Category Name" }
        
        let add = UIAlertAction(title: "Add", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
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
        if indexPath.section == 1 {
            performSegue(withIdentifier: "showParticipantsModal", sender: self)
        }
    }

    // MARK: - Save Action
    @IBAction func didTapSaveButton(_ sender: UIBarButtonItem) {
        guard let name = nameTextField.text, !name.isEmpty else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: startTimePicker.date)
        
        let sortedDays = allDaysOrdered.filter { selectedDays.contains($0) }
        let dateString = sortedDays.joined(separator: ", ")
        
        let iconName: String
        switch selectedCategory.lowercased() {
        case "friends": iconName = "person.2.fill"
        case "family": iconName = "house.fill"
        case "medical", "health": iconName = "cross.case.fill"
        default: iconName = "briefcase.fill"
        }
        
        let newAction = RoutineConversation(
            id: UUID().uuidString,
            iconName: iconName,
            categoryTitle: selectedCategory,
            status: "Scheduled",
            conversationTopic: name,
            topicImage: "mic.circle.fill",
            timeRange: timeString,
            description: selectedParticipants.isEmpty ? "No participants" : "With: \(selectedParticipants.joined(separator: ", "))",
            date: dateString,
            timeImage: "clock"
        )
        
        delegate?.didCreateNewAction(newAction)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Utilities
    func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false; view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() { view.endEditing(true) }
    @objc func textDidChange(_ sender: UITextField) { saveButton.isEnabled = !(sender.text?.isEmpty ?? true) }
}
