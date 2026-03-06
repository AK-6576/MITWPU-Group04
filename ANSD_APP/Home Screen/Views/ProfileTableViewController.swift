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
    
    // MARK: - Outlets (Personal Information)
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    // MARK: - Outlets (Vocal Profile)
    @IBOutlet weak var voiceStatusLabel: UILabel!
    @IBOutlet weak var updateProfileButton: UIButton!
    @IBOutlet weak var deleteProfileButton: UIButton!
    
    var incomingName: String?
    var incomingImage: UIImage?
    
    // MARK: - Storage Keys
    private let firstNameKey = "user_first_name"
    private let lastNameKey = "user_last_name"
    private let genderKey = "user_gender"
    private let dobKey = "user_dob"
    private let imageKey = "profileImage"
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHideKeyboardOnTap()
        setupTextFieldListeners()
        loadPersistentData()
        setupVoiceProfileButtons()
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshVoiceProfileStatus()
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
    
    // MARK: - Voice Profile Setup
    
    private func setupVoiceProfileButtons() {
        // Style the Update button — rounded corners, iOS native look
        updateProfileButton.layer.cornerRadius = 10
        updateProfileButton.clipsToBounds = true
        
        // Style the Delete button — rounded corners, iOS native look
        deleteProfileButton.layer.cornerRadius = 10
        deleteProfileButton.clipsToBounds = true
    }
    
    /// Check if a voice profile exists and update the status label accordingly
    private func refreshVoiceProfileStatus() {
        if let profile = VoiceProfileManager.shared.getVoiceProfile(byId: 0) {
            voiceStatusLabel.text = "Calibrated ✓"
            voiceStatusLabel.textColor = .systemGreen
            updateProfileButton.isEnabled = true
            deleteProfileButton.isEnabled = true
            print("ProfileScreen: Voice profile found — \(profile.name)")
        } else {
            voiceStatusLabel.text = "Not Calibrated"
            voiceStatusLabel.textColor = .systemGray
            updateProfileButton.isEnabled = false
            deleteProfileButton.isEnabled = false
        }
    }
    
    // MARK: - Voice Profile Actions
    
    @IBAction func updateProfileTapped(_ sender: Any) {
        let alert = UIAlertController(
            title: "Update Voice Profile",
            message: "This will re-record your voice profile. Your current profile will be replaced with the new recording.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            self?.navigateToVoiceCalibration()
        })
        present(alert, animated: true)
    }
    
    @IBAction func deleteProfileTapped(_ sender: Any) {
        let alert = UIAlertController(
            title: "Delete Voice Profile",
            message: "Are you sure you want to delete your voice profile? You will need to re-calibrate before using voice features.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            VoiceProfileManager.shared.deleteVoiceProfile(byId: 0)
            self?.refreshVoiceProfileStatus()
            
            // Show confirmation
            let confirmation = UIAlertController(
                title: "Deleted",
                message: "Your voice profile has been removed.",
                preferredStyle: .alert
            )
            confirmation.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(confirmation, animated: true)
        })
        present(alert, animated: true)
    }
    
    /// Navigate to Voice Calibration screen for re-recording
    private func navigateToVoiceCalibration() {
        // Try to find the VoiceCalibration storyboard or use the Onboarding storyboard
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let calibrationVC = storyboard.instantiateViewController(withIdentifier: "VoiceCalibrationViewController") as? VoiceCalibrationViewController {
            let navController = UINavigationController(rootViewController: calibrationVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
    
    // MARK: - Personal Info Actions
    
    // Dismisses the profile screen by popping or dismissing the view controller depending on presentation context.
    @IBAction func closeButtonTapped(_ sender: Any) {
        print("DEBUG: Close button tapped")
        
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
