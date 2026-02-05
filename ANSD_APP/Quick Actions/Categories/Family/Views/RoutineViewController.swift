import UIKit

// MARK: - Protocol for Data Consistency
protocol RoutineItemProtocol {
    var title: String { get set }
    var time: String { get }
    var notes: String { get set }
}



// MARK: - Unified Routine View Controller
class BaseRoutineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    /// Set this property when navigating to this screen to load correct data
    var category: ChatCategory = .family
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
    
    // REDUNDANCY RESOLVED: Single load function using RoutineRepository
    func loadData() {
        let data = RoutineRepository.getRoutineData(for: category)
        
        // We add .map { $0 } to tell Swift to treat each RoutineItem as a Protocol item
        self.routineList = data.map { $0 as! any RoutineItemProtocol as RoutineItemProtocol }
        self.originalList = data.map { $0 as! any RoutineItemProtocol as RoutineItemProtocol }
        
        self.title = "\(category)".capitalized + " Routine"
        tableView.reloadData()
    }
    
    // MARK: - Navigation & Menu
    func setupNavigationBarMenu() {
        let selectAction = UIAction(title: "Select", image: UIImage(systemName: "checkmark.circle")) { [weak self] _ in
            self?.tableView.setEditing(!(self?.tableView.isEditing ?? false), animated: true)
        }
        
        let sortTitle = UIAction(title: "Title (A-Z)", image: UIImage(systemName: "textformat")) { [weak self] _ in
            self?.routineList.sort { $0.title < $1.title }
            self?.tableView.reloadData()
        }
        
        let sortReset = UIAction(title: "Reset", image: UIImage(systemName: "arrow.counterclockwise")) { [weak self] _ in
            self?.routineList = self?.originalList ?? []
            self?.tableView.reloadData()
        }

        let sortByMenu = UIMenu(title: "Sort By", children: [sortReset, sortTitle])
        let mainMenu = UIMenu(title: "", children: [selectAction, sortByMenu])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis.circle"), target: nil, action: nil, menu: mainMenu)
    }

    // MARK: - TableView Logic
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routineList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoutineCell", for: indexPath) as! RoutineTableViewCell
        // Using the unified configuration method we created in RoutineTableViewCell
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
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self.routineList[indexPath.row].title = newName
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowInfo",
           let destination = (segue.destination as? UINavigationController)?.topViewController as? InfoViewController,
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
// These allow you to delete all the subclass files while keeping Storyboard working.
typealias FamilyRoutineViewController = BaseRoutineViewController
typealias FriendsRoutineViewController = BaseRoutineViewController
typealias OfficeRoutineViewController = BaseRoutineViewController
typealias RoutineViewController1 = BaseRoutineViewController
