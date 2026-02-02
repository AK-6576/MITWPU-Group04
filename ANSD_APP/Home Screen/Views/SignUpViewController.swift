import UIKit

// MARK: - UserDefaults Keys (DATA KEYS ONLY)
struct UserKeys {
    static let profile   = "user_profile_data"

    static let firstName = "first_name"
    static let lastName  = "last_name"
    static let email     = "email"
    static let password  = "password"
    static let dob       = "dob"
    static let phone     = "phone"
    static let gender    = "gender"
    static let image     = "profile_image"
}

// MARK: - SignUp View Controller
class SignUpViewController: UIViewController,
                            UITableViewDelegate,
                            UITableViewDataSource,
                            SignUpCellDelegate {

    @IBOutlet weak var tableView: UITableView!

    // UI title + storage key
    let formFields: [(title: String, key: String)] = [
        ("First Name", UserKeys.firstName),
        ("Last Name", UserKeys.lastName),
        ("Email", UserKeys.email),
        ("Password", UserKeys.password),
        ("Date of Birth", UserKeys.dob),
        ("Phone Number", UserKeys.phone)
    ]

    // Stores all user input
    var userAnswers: [String: Any] = [:]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none

        setupHideKeyboardOnTap()
    }

    // MARK: - Sign Up Action
    @IBAction func didTapSignUp(_ sender: Any) {
        view.endEditing(true)

        // Collect values from visible cells
        for row in 0..<formFields.count {
            let indexPath = IndexPath(row: row, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? SignUpTableViewCell {
                let field = formFields[row]
                userAnswers[field.key] = cell.inputTextField.text ?? ""
            }
        }

        // Save ONE profile dictionary
        UserDefaults.standard.set(userAnswers, forKey: UserKeys.profile)

        print("✅ SAVED PROFILE →", userAnswers)

        performSegue(withIdentifier: "toProfile", sender: self)
    }

    // MARK: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return formFields.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SignUpCell",
            for: indexPath
        ) as! SignUpTableViewCell

        let field = formFields[indexPath.row]

        cell.configure(
            title: field.title,
            placeholder: "Enter \(field.title)",
            index: indexPath.row
        )

        cell.delegate = self
        return cell
    }

    // MARK: - SignUpCellDelegate
    func didUpdateInput(text: String, rowIndex: Int) {
        let field = formFields[rowIndex]
        userAnswers[field.key] = text
    }

    // MARK: - Keyboard Handling
    private func setupHideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
