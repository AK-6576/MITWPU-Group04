import UIKit

class QuickActionsViewController: UITableViewController {

    // 1. DATA SOURCE
    // This holds the list of conversations we want to show.
    var actionsList: [RoutineConversation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the data from our repository
        actionsList = QuickActionsRepository.getAllActions()
        
        // Setup the Navigation Bar title and the "+" button
        title = "Quick Actions"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton))
        
        // --- VISUAL FIX ---
        // This removes the unwanted separator line above the first cell ("Scrum Meet").
        // It tells the table: "Don't reserve space for a header."
        tableView.tableHeaderView = UIView()
    }
    
    // Action when the "+" button is tapped
    @objc func didTapAddButton() {
        // We will add the "New Conversation" screen code here later
        print("Add button tapped")
    }

    // MARK: - TABLE VIEW CONFIGURATION

    // How many rows to display?
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionsList.count
    }
    
    // How tall is each row?
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    // What does each row look like?
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // 1. REUSE CELL
        // recycle an off-screen cell to save memory
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuickActionCell", for: indexPath)
        
        // 2. GET DATA
        // Get the specific item for this row number
        let item = actionsList[indexPath.row]
        
        // 3. CONFIGURE UI
        // We use "Tags" (numbers) to find the views we set up in Storyboard.
        // Tag 1 = Title, Tag 2 = Subtitle, Tag 3 = Icon Image
        if let titleLabel = cell.viewWithTag(1) as? UILabel,
           let subtitleLabel = cell.viewWithTag(2) as? UILabel,
           let iconView = cell.viewWithTag(3) as? UIImageView {
            
            // Set the text and image
            titleLabel.text = item.conversationTopic
            subtitleLabel.text = item.timeRange
            iconView.image = UIImage(systemName: item.iconName)
            
            // Style the Icon (make it look like a rounded button)
            iconView.layer.cornerRadius = 10
            iconView.backgroundColor = .systemGray6
            iconView.contentMode = .center
        }
        
        return cell
    }
}
