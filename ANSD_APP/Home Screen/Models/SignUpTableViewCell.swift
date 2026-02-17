//
//  SignUpTableViewCell.swift
//  Group_4-ANSD_App
//
//  Created by Daiwiik on 13/12/25.
//

import UIKit

protocol SignUpCellDelegate: AnyObject {
    func didUpdateInput(text: String, rowIndex: Int)
}

class SignUpTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputTextField: UITextField!
    
    weak var delegate: SignUpCellDelegate?
    var rowIndex: Int = 0
    let datePicker = UIDatePicker()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Figma Styling: Light Gray Background, Rounded Corners, No Border
        inputTextField.borderStyle = .none
        inputTextField.layer.cornerRadius = 10
        inputTextField.backgroundColor = UIColor.systemGray6
        inputTextField.delegate = self
        
        // Padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        inputTextField.leftView = paddingView
        inputTextField.leftViewMode = .always
    }

    func configure(title: String, placeholder: String, index: Int) {
        titleLabel.text = title
        inputTextField.placeholder = placeholder
        self.rowIndex = index
        
        // Reset state
        inputTextField.inputView = nil
        inputTextField.rightView = nil
        inputTextField.isSecureTextEntry = false
        
        // MARK: - Logic for Specific Fields
        if title.contains("Date") {
            setupDatePicker()
        } else if title.contains("Password") {
        } else if title.contains("Email") {
            inputTextField.keyboardType = .emailAddress
        } else if title.contains("Phone") {
            inputTextField.keyboardType = .phonePad
        } else {
            inputTextField.keyboardType = .default
        }
    }
    
    // MARK: - Date Picker Logic
    func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        // Toolbar for "Done"
        let toolbar = UIToolbar(); toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissDate))
        toolbar.setItems([UIBarButtonItem(systemItem: .flexibleSpace), doneBtn], animated: true)
        
        inputTextField.inputView = datePicker
        inputTextField.inputAccessoryView = toolbar
    }
    
    @objc func dateChanged() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        inputTextField.text = formatter.string(from: datePicker.date)
        delegate?.didUpdateInput(text: inputTextField.text ?? "", rowIndex: rowIndex)
    }
    
    @objc func dismissDate() { inputTextField.resignFirstResponder() }
    
    @objc func togglePasswordVisibility(_ sender: UIButton) {
        inputTextField.isSecureTextEntry.toggle()
        let imageName = inputTextField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.didUpdateInput(text: textField.text ?? "", rowIndex: rowIndex)
    }
}
