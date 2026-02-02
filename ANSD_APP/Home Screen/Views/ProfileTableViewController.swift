import UIKit

class ProfileTableViewController: UITableViewController,
                                  UIImagePickerControllerDelegate,
                                  UINavigationControllerDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGenderMenu()
        setupImageTap()
        setupHideKeyboardOnTap()
        loadProfile()
    }

    // MARK: - UI Setup
    private func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }

    // MARK: - Load Profile
    private func loadProfile() {
        guard let profile =
                UserDefaults.standard.dictionary(forKey: UserKeys.profile)
                as? [String: Any] else {
            print("❌ No profile found")
            return
        }

        firstNameTextField.text = profile[UserKeys.firstName] as? String ?? ""
        lastNameTextField.text  = profile[UserKeys.lastName] as? String ?? ""

        if let gender = profile[UserKeys.gender] as? String {
            genderButton.setTitle(gender, for: .normal)
        }

        if let dobString = profile[UserKeys.dob] as? String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            if let date = formatter.date(from: dobString) {
                datePicker.date = date
            }
        }

        if let imageData = profile[UserKeys.image] as? Data {
            profileImageView.image = UIImage(data: imageData)
        }

        print("📥 PROFILE LOADED →", profile)
    }

    // MARK: - Save Profile
    @IBAction func closeButtonTapped(_ sender: Any) {
        saveProfile()
        navigationController?.popViewController(animated: true)
    }

    private func saveProfile() {
        // 🔥 IMPORTANT: overwrite profile cleanly
        var profile: [String: Any] = [:]

        profile[UserKeys.firstName] = firstNameTextField.text ?? ""
        profile[UserKeys.lastName]  = lastNameTextField.text ?? ""

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        profile[UserKeys.dob] = formatter.string(from: datePicker.date)

        if let title = genderButton.title(for: .normal) {
            profile[UserKeys.gender] = title
        }

        if let image = profileImageView.image,
           let data = image.jpegData(compressionQuality: 0.7) {
            profile[UserKeys.image] = data
        }

        UserDefaults.standard.set(profile, forKey: UserKeys.profile)

        print("💾 PROFILE SAVED →", profile)
    }

    // MARK: - Image Picker
    private func setupImageTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(changePhoto))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tap)
    }

    @objc private func changePhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        if let image = info[.originalImage] as? UIImage {
            profileImageView.image = image
        }
        dismiss(animated: true)
    }

    // MARK: - Gender Menu
    private func setupGenderMenu() {
        let genders = ["Male", "Female", "Other"]

        let actions = genders.map { gender in
            UIAction(title: gender) { _ in
                self.genderButton.setTitle(gender, for: .normal)
            }
        }

        genderButton.menu = UIMenu(title: "Gender", children: actions)
        genderButton.showsMenuAsPrimaryAction = true
    }

    // MARK: - Keyboard
    private func setupHideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
