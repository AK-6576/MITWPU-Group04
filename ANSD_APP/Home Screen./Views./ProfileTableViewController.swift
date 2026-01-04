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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let name = incomingName, !name.isEmpty {
            firstNameTextField.text = name
            firstNameTextField.textColor = .label
        } else {
            firstNameTextField.text = "Steve"
            firstNameTextField.textColor = .systemGray3
        }
        
        if let image = incomingImage { profileImageView.image = image }
        
        setupHideKeyboardOnTap()
        setupGenderMenu()
        setupTextFieldListeners()
    }
    
    func setupTextFieldListeners() {
        firstNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        firstNameTextField.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
    }

    @objc func textFieldDidBeginEditing() {
        firstNameTextField.textColor = .label
    }

    @objc func textFieldDidChange() {
        performAutoSave()
        firstNameTextField.textColor = .label
        performAutoSave()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupProfileDesign()
    }
    
    func setupProfileDesign() {
        guard let profileImageView = profileImageView else { return }
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    func setupGenderMenu() {
        guard genderButton != nil else { return }
        let male = UIAction(title: "Male", handler: { _ in self.updateGenderTitle("Male") })
        let female = UIAction(title: "Female", handler: { _ in self.updateGenderTitle("Female") })
        let other = UIAction(title: "Prefer not to say", handler: { _ in self.updateGenderTitle("Prefer not to say") })
        genderButton.menu = UIMenu(children: [male, female, other])
        genderButton.showsMenuAsPrimaryAction = true
    }
    
    func updateGenderTitle(_ title: String) {
        genderButton.setTitle(title, for: .normal)
    }
    
    func performAutoSave() {
        let name = firstNameTextField.text ?? "User"
        let image = profileImageView.image
        delegate?.didUpdateProfile(firstName: name, image: image)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
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
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        performAutoSave()
        
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func setupHideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
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
