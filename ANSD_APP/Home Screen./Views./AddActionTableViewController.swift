import UIKit

// MARK: - Protocol
protocol AddActionDelegate: AnyObject {
    func didCreateNewAction(_ action: RoutineConversation)
}

// MARK: - View Controller
class AddActionTableViewController: UITableViewController, ParticipantsSelectionDelegate {

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
    
    // Data Models
    var selectedCategory: String = "Office"
    var selectedDays: Set<String> = ["Monday"]
    var selectedParticipants: [String] = []
    
    var availableCategories: [String] = ["Friends", "Family", "Office"]
    
    let allDaysOrdered = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupKeyboardDismissal()
        
        // Initial UI State
        participantsLabel.text = "None"
        saveButton.isEnabled = false
        
        // Setup Drop-downs
        setupDayCell()
        setupCategoryCell()
        
        // Input Listeners
        nameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    // MARK: - 1. Days Drop-down (Multi-Select FIXED)
        func setupDayCell() {
            // Create the button
            dayPopupButton = createPopupButton(actionHandler: { _ in })
            
            // VISUAL FIX: Ensure the button's tint (which affects the checkmark color in the menu) is System Blue
            dayPopupButton?.tintColor = .systemBlue
            
            // Configure Text Color (Black)
            if var config = dayPopupButton?.configuration {
                config.titleLineBreakMode = .byTruncatingTail
                config.baseForegroundColor = .label // Text is Black
                dayPopupButton?.configuration = config
            }
            
            updateDayMenu()
            daysCell.accessoryView = dayPopupButton
        }
            
        func updateDayMenu() {
            var actions: [UIAction] = []
            
            for day in allDaysOrdered {
                let isSelected = selectedDays.contains(day)
                
                // The checkmark appears automatically based on 'state: .on'
                let action = UIAction(title: day,
                                      // This keeps the menu open so you can see the tick appear/disappear
                                      attributes: [.keepsMenuPresented],
                                      state: isSelected ? .on : .off) { [weak self] sender in
                    
                    guard let self = self else { return }
                    
                    // 1. Logic Update
                    self.toggleDay(sender.title)
                    
                    // 2. Visual Update: Manually toggle the checkmark state on the sender
                    sender.state = self.selectedDays.contains(sender.title) ? .on : .off
                    
                    // 3. Button Label Update
                    self.updateDayButtonText()
                    
                    // 4. Important: Replace the menu to persist visual state changes if needed in older iOS versions,
                    // but usually sender.state handles it. If ticks don't appear, un-comment the next line:
                    // self.updateDayMenu()
                }
                
                actions.append(action)
            }
            
            let menu = UIMenu(title: "Select Days", children: actions)
            dayPopupButton?.menu = menu
            
            updateDayButtonText()
        }
    func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            // Optional: Prevent deselection if it's the last day remaining
            if selectedDays.count > 1 {
                selectedDays.remove(day)
            }
        } else {
            selectedDays.insert(day)
        }
        // NOTE: Do NOT call updateDayMenu() here. It will close the menu.
    }
    
    func updateDayButtonText() {
        let text = getFormattedDateString()
        dayPopupButton?.configuration?.title = text
    }

    // MARK: - 2. Category Drop-down (FIXED)
        func setupCategoryCell() {
            // 1. Create the button
            categoryPopupButton = createPopupButton(actionHandler: { [weak self] action in
                self?.updateCategory(action.title)
            })
            
            // 2. Build the menu list
            setupCategoryMenu()
            
            // 3. Add to the table view
            categoryCell.accessoryView = categoryPopupButton
            
            // 4. CRITICAL FIX: Show "Office" (or default) immediately on load
            updateCategory(selectedCategory)
        }
        
        func setupCategoryMenu() {
            let selectionHandler: (UIAction) -> Void = { [weak self] action in
                self?.updateCategory(action.title)
            }
            
            var actions: [UIAction] = []
            
            // 1. Build Categories from the Dynamic List
            for cat in availableCategories {
                let iconName = getSymbolForCategory(cat)
                let color = getColorForCategory(cat)
                
                // Generate Colored Icon
                let coloredImage = UIImage(systemName: iconName)?
                    .withTintColor(color, renderingMode: .alwaysOriginal)
                
                // Create Action (Standard Black Text, Colored Icon)
                let action = UIAction(title: cat,
                                      image: coloredImage,
                                      state: (cat == selectedCategory) ? .on : .off, // Show tick if selected
                                      handler: selectionHandler)
                actions.append(action)
            }
            
            // 2. Build "Create Own" (Blue Icon, Blue Text logic applied in helper if needed, but usually kept separate)
            let plusImage = UIImage(systemName: "plus")?
                .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            
            let createOwnAction = UIAction(title: "Create Own...",
                                           image: plusImage,
                                           attributes: [], // Keeps text standard color
                                           handler: { [weak self] _ in
                self?.showCustomCategoryAlert()
            })
            
            // 3. Assemble Menu
            let menu = UIMenu(title: "Choose Category", children: actions + [createOwnAction])
            categoryPopupButton?.menu = menu
        }
    
        func updateCategory(_ category: String) {
            self.selectedCategory = category
            let iconName = getSymbolForCategory(category)
            let color = getColorForCategory(category)
            
            if var config = categoryPopupButton?.configuration {
                // 1. Text Color: Black (using .label adapts to Dark Mode correctly, or use .black to force absolute black)
                config.baseForegroundColor = .label
                config.title = category
                
                // 2. Icon Color: Force the specific color
                // We use a configuration to ensure the size is correct, then tint it
                let symbolConfig = UIImage.SymbolConfiguration(scale: .medium)
                let coloredImage = UIImage(systemName: iconName, withConfiguration: symbolConfig)?
                    .withTintColor(color, renderingMode: .alwaysOriginal)
                
                config.image = coloredImage
                config.imagePadding = 8
                
                categoryPopupButton?.configuration = config
            }
        }
    
    // MARK: - Helper: Button Factory
    func createPopupButton(actionHandler: @escaping UIActionHandler) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.up.chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.titleLineBreakMode = .byTruncatingTail
        
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        
        // Frame/Alignment
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 35)
        button.contentHorizontalAlignment = .trailing
        
        return button
    }
    
    // MARK: - Logic: Formatting
    func getFormattedDateString() -> String {
        let weekdays: Set<String> = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        let weekends: Set<String> = ["Saturday", "Sunday"]
        
        if selectedDays.isEmpty { return "Select" }
        if selectedDays.count == 7 { return "Every Day" }
        if selectedDays == weekdays { return "Every Weekday" }
        if selectedDays == weekends { return "Every Weekend" }
        
        // Sort and join
        let sorted = allDaysOrdered.filter { selectedDays.contains($0) }
        return sorted.map { String($0.prefix(3)) }.joined(separator: ", ")
    }
    
    // MARK: - Custom Alert
        func showCustomCategoryAlert() {
            let alert = UIAlertController(title: "New Category", message: "Enter category name", preferredStyle: .alert)
            alert.addTextField { tf in
                tf.placeholder = "Category Name"
                tf.autocapitalizationType = .words
            }
            
            let add = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
                guard let self = self,
                      let text = alert.textFields?.first?.text,
                      !text.isEmpty else { return }
                
                // 1. Add to our data source if it doesn't exist
                if !self.availableCategories.contains(text) {
                    self.availableCategories.append(text)
                }
                
                // 2. Select the new category visually
                self.updateCategory(text)
                
                // 3. REBUILD the menu so the new item appears in the list next time
                self.setupCategoryMenu()
            }
            
            alert.addAction(add)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    
    // MARK: - Table View Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Adjust these indices to match your storyboard
        if indexPath.section == 0 && indexPath.row == 1 {
            openParticipantsModal()
        }
    }
        
    // MARK: - Participants Logic
    func openParticipantsModal() {
        let pickerVC = ParticipantsViewController()
        pickerVC.delegate = self
        pickerVC.initialSelectedNames = self.selectedParticipants
        
        let nav = UINavigationController(rootViewController: pickerVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    func didSelectParticipants(_ names: [String]) {
        self.selectedParticipants = names
        if names.isEmpty {
            participantsLabel.text = "None"
            participantsLabel.textColor = .secondaryLabel
        } else {
            participantsLabel.text = names.joined(separator: ", ")
            participantsLabel.textColor = .label
        }
    }
    
    // MARK: - Save Action
    @IBAction func didTapSaveButton(_ sender: UIBarButtonItem) {
        guard let name = nameTextField.text, !name.isEmpty else { return }
            
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: startTimePicker.date)
        
        let dateString = getFormattedDateString()
        let iconName = getSymbolForCategory(selectedCategory)
        
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
    
    // MARK: - Utilities
    func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false; view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() { view.endEditing(true) }
    @objc func textDidChange(_ sender: UITextField) { saveButton.isEnabled = !(sender.text?.isEmpty ?? true) }
}

// MARK: - Icon Logic Helper
func getSymbolForCategory(_ name: String) -> String {
    let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
    
    switch lower {
    case "friends", "hangout": return "person.2.fill"
    case "family", "home", "house": return "house.fill"
    case "date", "partner": return "heart.fill"
    case "office", "work", "meeting": return "briefcase.fill"
    case "school", "study", "class", "university": return "book.fill"
    case "coding", "dev", "tech": return "laptopcomputer"
    case "medical", "doctor", "health": return "cross.case.fill"
    case "gym", "workout", "fitness": return "figure.run"
    case "meditation": return "lungs.fill"
    case "groceries", "shopping": return "cart.fill"
    case "cooking", "dinner", "food": return "fork.knife"
    case "cleaning", "laundry": return "washer.fill"
    case "gaming": return "gamecontroller.fill"
    case "movie", "cinema": return "popcorn.fill"
    case "music": return "music.note"
    case "travel": return "airplane"
    case "bank", "finance", "money": return "banknote.fill"
    default: return "tag.fill"
    }
}

func getColorForCategory(_ name: String) -> UIColor {
    let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
    
    // 1. Check for specific hardcoded matches first
    switch lower {
    case "family", "date", "partner", "home": return .systemPink
    case "office", "work", "coding":          return .systemBlue
    case "friends", "gaming", "party":        return .systemOrange
    case "gym", "health", "medical":          return .systemGreen
    case "finance", "money", "bank":          return .systemMint
    case "create own...":                     return .systemBlue
        
    // 2. Dynamic Fallback: Pick a color based on the name's hash
    default:
        let palette: [UIColor] = [
            .systemYellow,
            .systemGreen, .systemTeal, .systemBlue,
            .systemIndigo, .systemPurple, .systemPink, .systemBrown
        ]
        
        // Use the string's hash to pick a consistent index
        let hash = abs(name.hashValue)
        let index = hash % palette.count
        return palette[index]
    }
}
