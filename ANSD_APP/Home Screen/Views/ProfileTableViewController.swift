//
//  ProfileTableViewController.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 12/12/25.
//

import UIKit

// Protocol to update Home Screen instantly
protocol ProfileUpdateDelegate: AnyObject {
    func didUpdateProfile(firstName: String, image: UIImage?)
}

class ProfileTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    weak var delegate: ProfileUpdateDelegate?
    
    // MARK: - Outlets
    // Make sure these are connected in Storyboard!
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var impairmentSlider: UISlider!
    
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
    
    // === FIX 1: THIS MAKES THE IMAGE CIRCULAR ===
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure the image view is a perfect circle
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        // Optional: Add a border to make it look cleaner
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        performAutoSave()
    }
    
    // MARK: - Actions
    
    // === FIX 2: THIS FIXES THE DISMISS X BUTTON ===
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
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        performAutoSave()
        closeButtonTapped(sender)
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
        
        // 1. Save to Disk
        UserDefaults.standard.set(name, forKey: firstNameKey)
        UserDefaults.standard.set(lastName, forKey: lastNameKey)
        
        // 2. Broadcast INSTANTLY to Home Screen (The Name Fix)
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
            // Update UI
            profileImageView.image = finalImage
            
            // Save to Disk
            if let data = finalImage.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(data, forKey: imageKey)
            }
            
            // Broadcast INSTANTLY to Home Screen (The Image Fix)
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
