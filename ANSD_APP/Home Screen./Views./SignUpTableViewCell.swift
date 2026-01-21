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

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40))
        inputTextField.leftView = paddingView
        inputTextField.leftViewMode = .always
        
        inputTextField.delegate = self
    }

    func configure(title: String, placeholder: String, index: Int) {
        titleLabel.text = title
        inputTextField.placeholder = placeholder
        self.rowIndex = index
        
        if title.contains("Email") {
            inputTextField.keyboardType = .emailAddress
        } else if title.contains("Phone") {
            inputTextField.keyboardType = .phonePad
        } else if title.contains("Password") {
            inputTextField.isSecureTextEntry = true
        } else if title.contains("Date") {
            inputTextField.keyboardType = .numbersAndPunctuation
        } else {
            inputTextField.keyboardType = .default
            inputTextField.isSecureTextEntry = false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.didUpdateInput(text: textField.text ?? "", rowIndex: rowIndex)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
