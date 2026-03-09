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
        setupGenderButton()
        loadPersistentData()
        
        // Initial Name Setup
        if firstNameTextField.text?.isEmpty ?? true {
            firstNameTextField.text = incomingName ?? "User"
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
    
    // MARK: - Gender Menu Setup
    private func setupGenderButton() {
        let options = ["Male", "Female", "Prefer not to say"]
        var actions = [UIAction]()
        
        for option in options {
            let action = UIAction(title: option) { [weak self] _ in
                self?.genderButton.setTitle(option, for: .normal)
                self?.performAutoSave()
            }
            actions.append(action)
        }
        
        genderButton.menu = UIMenu(children: actions)
        genderButton.showsMenuAsPrimaryAction = true
    }
    
    // MARK: - Voice Profile Setup
    
    /// Check if a voice profile exists and update the status label accordingly
    private func refreshVoiceProfileStatus() {
        if let profile = VoiceProfileManager.shared.getVoiceProfile(byId: 0) {
            voiceStatusLabel.text = "Calibrated ✓"
            voiceStatusLabel.textColor = .systemGreen
            print("ProfileScreen: Voice profile found — \(profile.name)")
        } else {
            voiceStatusLabel.text = "Not Calibrated"
            voiceStatusLabel.textColor = .systemGray
        }
    }
    
    // MARK: - Voice Profile Actions
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            // Vocal Profile is the 5th cell (index 4) in the first section
            if indexPath.row == 4 {
                handleVocalProfileTap()
            }
        } else if indexPath.section == 1 {
            // Logout is the only cell in the second section
            if indexPath.row == 0 {
                confirmSignOut()
            }
        }
    }
    
    private func handleVocalProfileTap() {
        if VoiceProfileManager.shared.getVoiceProfile(byId: 0) != nil {
            let actionSheet = UIAlertController(title: "Voice Profile", message: "Manage your voice profile", preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Update Profile", style: .default) { [weak self] _ in
                self?.navigateToVoiceCalibration()
            })
            
            actionSheet.addAction(UIAlertAction(title: "Delete Profile", style: .destructive) { [weak self] _ in
                VoiceProfileManager.shared.deleteVoiceProfile(byId: 0)
                self?.refreshVoiceProfileStatus()
                
                let confirmation = UIAlertController(title: "Deleted", message: "Your voice profile has been removed.", preferredStyle: .alert)
                confirmation.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(confirmation, animated: true)
            })
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // For iPad support
            if let popoverController = actionSheet.popoverPresentationController {
                if let cell = tableView.cellForRow(at: IndexPath(row: 4, section: 0)) {
                    popoverController.sourceView = cell
                    popoverController.sourceRect = cell.bounds
                }
            }
            
            present(actionSheet, animated: true)
        } else {
            navigateToVoiceCalibration()
        }
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
        lastNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
    }
    
    @objc func textFieldDidChange() {
        performAutoSave()
    }

    @objc func datePickerChanged() {
        performAutoSave()
    }
    
    func performAutoSave() {
        let name = firstNameTextField.text ?? "User"
        let lastName = lastNameTextField.text ?? ""
        let dob = datePicker.date
        let gender = genderButton.title(for: .normal) ?? "Select"
        
        // Persists the data to UserDefaults.
        UserDefaults.standard.set(name, forKey: firstNameKey)
        UserDefaults.standard.set(lastName, forKey: lastNameKey)
        UserDefaults.standard.set(gender, forKey: genderKey)
        UserDefaults.standard.set(dob, forKey: dobKey)
        
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
        if let savedGender = UserDefaults.standard.string(forKey: genderKey), savedGender != "Select" {
            genderButton.setTitle(savedGender, for: .normal)
        }
        if let savedDOB = UserDefaults.standard.object(forKey: dobKey) as? Date {
            datePicker.date = savedDOB
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
    
    // MARK: - Sign Out
    @objc private func confirmSignOut() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out? This will clear all local data.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.performSignOut()
        })
        present(alert, animated: true)
    }
    
    private func performSignOut() {
        FirebaseManager.shared.signOut { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Route to Login Screen
                    let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
                    if let loginNav = storyboard.instantiateInitialViewController() {
                        loginNav.modalPresentationStyle = .fullScreen
                        self?.present(loginNav, animated: true, completion: nil)
                    }
                case .failure(let error):
                    let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(errorAlert, animated: true)
                }
            }
        }
    }
}
