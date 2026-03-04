//
//  ProfileTableViewController.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 12/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// Defines the delegate protocol for propagating profile updates to the Home Screen.
protocol ProfileUpdateDelegate: AnyObject {
    func didUpdateProfile(firstName: String, image: UIImage?)
}

class ProfileTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    weak var delegate: ProfileUpdateDelegate?
    
    // MARK: - Outlets
    // Verifies outlet connections before use.
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    var incomingName: String?
    var incomingImage: UIImage?
    
    // MARK: - Storage Keys
    private let firstNameKey = "user_first_name"
    private let lastNameKey = "user_last_name"
    private let genderKey = "user_gender"
    private let dobKey = "user_dob"
    private let imageKey = "profileImage"
    private let impairmentKey = "user_impairment_level"
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHideKeyboardOnTap()
        setupTextFieldListeners()
        loadPersistentData()
        
        // Initial Name Setup
        if firstNameTextField.text?.isEmpty ?? true {
            firstNameTextField.text = incomingName ?? "Steve"
        }
        
        // Load Image
        if let data = UserDefaults.standard.data(forKey: imageKey),
           let savedImage = UIImage(data: data) {
            profileImageView.image = savedImage
        }
    }
    
        // Applies circular styling and a border to the profile image view.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Configures the image view with aspect fill and a rounded corner radius.
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        // Adds a subtle border around the profile photo for visual clarity.
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        performAutoSave()
    }
    
    // MARK: - Actions
    
    // Dismisses the profile screen by popping or dimissing the view controller depending on presentation context.
    @IBAction func closeButtonTapped(_ sender: Any) {
        print("DEBUG: Close button tapped") // Look for this in Console
        
        // Try to pop (if came from right)
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        }
        // Try to dismiss (if came from bottom)
        else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func setProfilePictureTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - Logic & Saving
    
    func setupTextFieldListeners() {
        firstNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc func textFieldDidChange() {
        performAutoSave()
    }
    
    func performAutoSave() {
        let name = firstNameTextField.text ?? "Steve"
        let lastName = lastNameTextField.text ?? ""
        
        // Persists the first name to UserDefaults.
        UserDefaults.standard.set(name, forKey: firstNameKey)
        UserDefaults.standard.set(lastName, forKey: lastNameKey)
        
        // Broadcasts the updated name via NotificationCenter to refresh the Home Screen greeting.
        NotificationCenter.default.post(name: NSNotification.Name("ProfileNameUpdated"),
                                      object: nil,
                                      userInfo: ["name": name])
    }
    
    func loadPersistentData() {
        if let savedName = UserDefaults.standard.string(forKey: firstNameKey) {
            firstNameTextField.text = savedName
        }
        if let savedLastName = UserDefaults.standard.string(forKey: lastNameKey) {
            lastNameTextField.text = savedLastName
        }
    }
    
    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImage: UIImage?
        
        if let edited = info[.editedImage] as? UIImage {
            selectedImage = edited
        } else if let original = info[.originalImage] as? UIImage {
            selectedImage = original
        }
        
        if let finalImage = selectedImage {
            // Updates the profile image view with the selected photo.
            profileImageView.image = finalImage
            
            // Persists the selected image as JPEG data in UserDefaults.
            if let data = finalImage.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(data, forKey: imageKey)
            }
            
            // Broadcasts the new profile image to the Home Screen via NotificationCenter.
            NotificationCenter.default.post(name: NSNotification.Name("ProfileImageUpdated"), object: finalImage)
        }
        dismiss(animated: true)
    }
    
    // MARK: - Keyboard Handling
    func setupHideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
