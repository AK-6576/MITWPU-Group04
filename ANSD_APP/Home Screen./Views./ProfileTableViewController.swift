//
//  ProfileTableViewController.swift
//  Group_4-ANSD_App
//
//  Created by Daiwiik Harihar on 10/12/25.
//

import UIKit

protocol ProfileUpdateDelegate: AnyObject {
    func didUpdateProfile(firstName: String, image: UIImage?)
}

class ProfileTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: ProfileUpdateDelegate?
    
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    var incomingName: String?
    var incomingImage: UIImage?
    
    private let genderKey = "user_gender"
    private let dobKey = "user_dob"
    
    // Function - Initializes the view lifecycle, setting up default values, UI design, listeners, and loading persistent data.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let name = incomingName, !name.isEmpty {
            firstNameTextField.text = name
            firstNameTextField.textColor = .label
        } else {
            firstNameTextField.text = "Steve"
            firstNameTextField.textColor = .black
        }
        
        if let image = incomingImage { profileImageView.image = image }
        
        setupHideKeyboardOnTap()
        setupGenderMenu()
        setupTextFieldListeners()
        
        setupDatePicker()
        loadPersistentData()
    }
    
    // Function - Adjusts the subview layout, specifically ensuring the profile picture design is applied after layout passes.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupProfileDesign()
    }
    
    // MARK: - Setup & Configuration
    
    // Function - Configures the profile image view with a circular shape and border.
    func setupProfileDesign() {
        guard let profileImageView = profileImageView else { return }
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    // Function - Attaches event listeners to the text fields to handle editing changes.
    func setupTextFieldListeners() {
        firstNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        firstNameTextField.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
    }
    
    // Function - Sets up the date picker target to handle value changes.
    func setupDatePicker() {
        datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
    }
    
    // MARK: - Persistence (Saving & Loading)
    
    // Function - Loads saved gender and date of birth from UserDefaults, defaulting to Male if no gender is saved.
    func loadPersistentData() {
        if let savedGender = UserDefaults.standard.string(forKey: genderKey) {
            genderButton.setTitle(savedGender, for: .normal)
        } else {
            updateGender("Male")
        }
        
        if let savedDate = UserDefaults.standard.object(forKey: dobKey) as? Date {
            datePicker.date = savedDate
        }
    }

    // MARK: - Actions & Handlers

    // Function - Saves the selected date to UserDefaults when the date picker value changes.
    @objc func datePickerChanged(_ sender: UIDatePicker) {
        UserDefaults.standard.set(sender.date, forKey: dobKey)
    }

    // Function - Configures the gender selection menu with available options and their handlers.
    func setupGenderMenu() {
        guard genderButton != nil else { return }
        
        let male = UIAction(title: "Male", handler: { _ in self.updateGender("Male") })
        let female = UIAction(title: "Female", handler: { _ in self.updateGender("Female") })
        let other = UIAction(title: "Prefer not to say", handler: { _ in self.updateGender("Prefer not to say") })
        
        genderButton.menu = UIMenu(children: [male, female, other])
        genderButton.showsMenuAsPrimaryAction = true
    }
    
    // Function - Updates the gender button title and saves the selection to UserDefaults.
    func updateGender(_ title: String) {
        genderButton.setTitle(title, for: .normal)
        UserDefaults.standard.set(title, forKey: genderKey)
    }
    
    // Function - Resets the text color to the default label color when editing begins.
    @objc func textFieldDidBeginEditing() {
        firstNameTextField.textColor = .label
    }

    // Function - Triggers an auto-save operation whenever the text field content changes.
    @objc func textFieldDidChange() {
        performAutoSave()
        firstNameTextField.textColor = .label
    }
    
    // Function - Captures current input and notifies the delegate of profile updates.
    func performAutoSave() {
        let name = firstNameTextField.text ?? "User"
        let image = profileImageView.image
        delegate?.didUpdateProfile(firstName: name, image: image)
    }
    
    // MARK: - Button Actions
    
    // Function - Dismisses the current view controller, popping from navigation stack if applicable.
    @IBAction func closeButtonTapped(_ sender: Any) {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // Function - Opens the image picker to allow the user to select a profile picture.
    @IBAction func setProfilePictureTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // Function - Saves the profile changes and dismisses the view controller.
    @IBAction func saveButtonTapped(_ sender: Any) {
        performAutoSave()
        
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Utilities
    
    // Function - Adds a gesture recognizer to the view to dismiss the keyboard on tap.
    func setupHideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // Function - Resigns the first responder status to hide the keyboard.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Function - Delegate method handling the image selection, updating the UI, and saving the image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImage: UIImage?
        
        if let image = info[.editedImage] as? UIImage {
            selectedImage = image
        } else if let image = info[.originalImage] as? UIImage {
            selectedImage = image
        }
        
        if let finalImage = selectedImage {
            profileImageView.image = finalImage
            performAutoSave()
        }
        
        dismiss(animated: true)
    }
}
